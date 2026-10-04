import { SQL } from "bun";
import { writeFileSync, readFileSync } from "fs";

// 1. Configuración de conexión a PostgreSQL
const DB_URL =
  process.env.DATABASE_URL || "postgres://acha:acha@100.117.32.119:5555/lab6";
const db = new SQL(DB_URL);

// 2. Definición de las 5 consultas de negocio
const QUERIES = [
  {
    id: "Q1",
    label: "Q1: Posts Usuario",
    sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
          SELECT post_id, thread_id, account_id, created, visible, comment
          FROM post WHERE account_id = 1;`,
  },
  {
    id: "Q2",
    label: "Q2: Count Usuario",
    sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
          SELECT COUNT(*) AS total_posts FROM post WHERE account_id = 1;`,
  },
  {
    id: "Q3",
    label: "Q3: Thread Visible",
    sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
          SELECT post_id, thread_id, account_id, created, comment
          FROM post WHERE thread_id = 1 AND visible = TRUE;`,
  },
  {
    id: "Q4",
    label: "Q4: Count Hilo+User",
    sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
          SELECT COUNT(*) AS total_posts FROM post WHERE account_id = 1 AND thread_id = 1;`,
  },
  {
    id: "Q5",
    label: "Q5: Thread Mes Ord",
    sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
          SELECT post_id, thread_id, account_id, created, comment
          FROM post
          WHERE thread_id = 1 AND visible = TRUE
            AND created >= date_trunc('month', CURRENT_TIMESTAMP)
            AND created < date_trunc('month', CURRENT_TIMESTAMP) + INTERVAL '1 month'
          ORDER BY created ASC;`,
  },
];

// 3. Medición sistemática con EXPLAIN ANALYZE
async function runBenchmark(label: string) {
  console.log(`\n-> Evaluando ${label}...`);
  const results: Record<
    string,
    { avg: number; std: number; node: string; buffers: number }
  > = {};

  for (const q of QUERIES) {
    const times: number[] = [];
    let nodeType = "";
    let totalHits = 0;

    for (let i = 0; i < 12; i++) {
      const res = (await db.unsafe(q.sql)) as any[];
      const planInfo = res[0]["QUERY PLAN"][0];
      times.push(planInfo["Execution Time"]);
      nodeType = planInfo["Plan"]["Node Type"];
      totalHits += planInfo["Plan"]["Shared Hit Blocks"] ?? 0;
    }

    const avg = times.reduce((a, b) => a + b, 0) / times.length;
    const std = Math.sqrt(
      times.reduce((acc, t) => acc + Math.pow(t - avg, 2), 0) /
        (times.length - 1),
    );
    const buffers = totalHits / times.length;

    results[q.id] = { avg, std, node: nodeType, buffers };
    console.log(
      `   ${q.id}: ${avg.toFixed(3)} ms ± ${std.toFixed(3)} | Nodo: ${nodeType} | Búfers: ${buffers.toFixed(1)}`,
    );
  }

  return results;
}

// 4. Flujo Principal
async function main() {
  console.log("=== BENCHMARK DE INDEXACIÓN POSTGRESQL (BUN + TYPESCRIPT) ===");

  // A. Eliminar índices secundarios para la línea base
  console.log("-> Eliminando índices personalizados en 'post'...");
  const indexes = (await db.unsafe(
    "SELECT indexname FROM pg_indexes WHERE tablename = 'post' AND indexname != 'post_pkey';",
  )) as any[];
  for (const row of indexes) {
    await db.unsafe(`DROP INDEX IF EXISTS ${row.indexname};`);
  }

  // B. Medir Línea Base (Sin Índices)
  const baseline = await runBenchmark("Línea Base (Sin Índices Secundarios)");

  // C. Aplicar sql/indexes.sql
  console.log("\n-> Creando índices desde sql/indexes.sql...");
  const script = readFileSync("sql/indexes.sql", "utf-8");
  for (const stmt of script
    .split(";")
    .map((s) => s.trim())
    .filter(Boolean)) {
    await db.unsafe(stmt + ";");
  }

  // D. Medir con Índices B-Tree
  const indexed = await runBenchmark("Rendimiento con Índices B-Tree");

  // E. Guardar datos JSON con las métricas recién generadas
  const jsonPath = "benchmark_results.json";
  writeFileSync(
    jsonPath,
    JSON.stringify({ baseline, indexed }, null, 2),
    "utf-8",
  );
  console.log(`\n-> Datos actualizados guardados en ${jsonPath}`);

  // F. Invocar plot.py con el archivo de resultados recién generados
  console.log("-> Invocando plot.py con los nuevos valores generados...");
  const plotProc = Bun.spawn(["python3", "src/plot.py", jsonPath], {
    stdout: "inherit",
    stderr: "inherit",
  });
  await plotProc.exited;

  // G. Compilar Typst
  console.log("\n-> Compilando reporte Typst...");
  const typstProc = Bun.spawn([
    "typst",
    "compile",
    "doc/main.typ",
    "doc/main.pdf",
  ]);
  await typstProc.exited;
  Bun.spawnSync(["cp", "doc/main.pdf", "main.pdf"]);
  console.log("   ✓ doc/main.pdf y main.pdf compilados exitosamente.");

  // H. Resumen en consola
  console.log("\n==================== RESUMEN DE MEJORAS ====================");
  console.log("Consulta | Base (ms) | Índices (ms) | Speedup");
  console.log("---------+-----------+--------------+---------");
  for (const q of QUERIES) {
    const bT = baseline[q.id].avg.toFixed(2);
    const iT =
      indexed[q.id].avg >= 0.1
        ? indexed[q.id].avg.toFixed(2)
        : indexed[q.id].avg.toFixed(3);
    const sp = (baseline[q.id].avg / indexed[q.id].avg).toFixed(1) + "x";
    console.log(
      `   ${q.id}    | ${bT.padStart(7)} ms | ${iT.padStart(8)} ms | ${sp.padStart(7)}`,
    );
  }
  console.log("============================================================\n");

  await db.close();
}

main();
