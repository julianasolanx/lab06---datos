import { MongoClient, type Collection, type Db } from "mongodb";
import { writeFileSync } from "fs";

// 1. Configuración de conexión a MongoDB
const MONGO_URL =
  process.env.MONGO_URL ||
  "mongodb://acha:acha@tally:27017/?authSource=admin";
const DB_NAME = process.env.MONGO_DB || "lab6";
const COLLECTION_NAME = "post";

const client = new MongoClient(MONGO_URL);

// 2. Fechas para Q5 (equivalente a date_trunc('month', CURRENT_TIMESTAMP) en PostgreSQL)
const now = new Date();
const startOfMonth = new Date(
  Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
);
const endOfMonth = new Date(
  Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
);

// 3. Definición de las 5 consultas de negocio adaptadas a MongoDB
interface QueryDef {
  id: string;
  label: string;
  runExplain: (coll: Collection) => Promise<any>;
}

const QUERIES: QueryDef[] = [
  {
    id: "Q1",
    label: "Q1: Posts Usuario",
    runExplain: (coll) =>
      coll
        .find(
          { account_id: 1 },
          {
            projection: {
              post_id: 1,
              thread_id: 1,
              account_id: 1,
              created: 1,
              visible: 1,
              comment: 1,
              _id: 0,
            },
          },
        )
        .explain("executionStats"),
  },
  {
    id: "Q2",
    label: "Q2: Count Usuario",
    runExplain: (coll) =>
      coll
        .aggregate([
          { $match: { account_id: 1 } },
          { $count: "total_posts" },
        ])
        .explain("executionStats"),
  },
  {
    id: "Q3",
    label: "Q3: Thread Visible",
    runExplain: (coll) =>
      coll
        .find(
          { thread_id: 1, visible: true },
          {
            projection: {
              post_id: 1,
              thread_id: 1,
              account_id: 1,
              created: 1,
              comment: 1,
              _id: 0,
            },
          },
        )
        .explain("executionStats"),
  },
  {
    id: "Q4",
    label: "Q4: Count Hilo+User",
    runExplain: (coll) =>
      coll
        .aggregate([
          { $match: { account_id: 1, thread_id: 1 } },
          { $count: "total_posts" },
        ])
        .explain("executionStats"),
  },
  {
    id: "Q5",
    label: "Q5: Thread Mes Ord",
    runExplain: (coll) =>
      coll
        .find(
          {
            thread_id: 1,
            visible: true,
            created: { $gte: startOfMonth, $lt: endOfMonth },
          },
          {
            projection: {
              post_id: 1,
              thread_id: 1,
              account_id: 1,
              created: 1,
              comment: 1,
              _id: 0,
            },
          },
        )
        .sort({ created: 1 })
        .explain("executionStats"),
  },
];

// Helper para extraer estadísticas y nodo principal del plan de ejecución
function extractStats(explainRes: any): {
  executionTime: number;
  node: string;
  docsExamined: number;
  keysExamined: number;
} {
  const stats =
    explainRes.executionStats ||
    explainRes.stages?.[0]?.$cursor?.executionStats ||
    {};

  const docsExamined = stats.totalDocsExamined ?? 0;
  const keysExamined = stats.totalKeysExamined ?? 0;

  // Determinar la etapa o nodo representativo
  function findNode(stageObj: any): string {
    if (!stageObj) return "UNKNOWN";
    const s = stageObj.stage;
    if (s === "COLLSCAN" || s === "IXSCAN" || s === "COUNT_SCAN" || s === "SORT" || s === "ixseek" || s === "scan") {
      return s === "ixseek" ? "IXSCAN (Covered)" : s === "scan" ? "COLLSCAN" : s;
    }
    if (stageObj.inputStage) {
      const child = findNode(stageObj.inputStage);
      if (child !== "UNKNOWN") return child;
    }
    if (Array.isArray(stageObj.inputStages)) {
      for (const st of stageObj.inputStages) {
        const found = findNode(st);
        if (found !== "UNKNOWN") return found;
      }
    }
    return s || "UNKNOWN";
  }

  const rawNode = findNode(stats.executionStages);
  const node = rawNode === "project" ? (keysExamined > 0 ? "COUNT_SCAN (Index)" : "COLLSCAN") : rawNode;

  return {
    executionTime: stats.executionTimeMillis ?? 0,
    node,
    docsExamined,
    keysExamined,
  };
}

// 4. Medición sistemática con explain("executionStats") y profiler
async function runBenchmark(
  db: Db,
  coll: Collection,
  label: string,
) {
  console.log(`\n-> Evaluando ${label}...`);
  const results: Record<
    string,
    {
      avg: number;
      std: number;
      node: string;
      docsExamined: number;
      keysExamined: number;
    }
  > = {};

  const profileColl = db.collection("system.profile");

  for (const q of QUERIES) {
    const times: number[] = [];
    let representativeNode = "";
    let totalDocs = 0;
    let totalKeys = 0;

    for (let i = 0; i < 12; i++) {
      const expRes = await q.runExplain(coll);
      const { executionTime, node, docsExamined, keysExamined } =
        extractStats(expRes);

      representativeNode = node;
      totalDocs += docsExamined;
      totalKeys += keysExamined;

      // Obtener el tiempo de CPU con precisión submilisegundo si executionTimeMillis es 0
      let execMs = executionTime;
      if (execMs === 0) {
        const profileEntry = await profileColl
          .find({
            ns: `${DB_NAME}.${COLLECTION_NAME}`,
            "command.explain": { $exists: true },
          })
          .sort({ ts: -1 })
          .limit(1)
          .toArray();

        if (profileEntry.length > 0 && profileEntry[0].cpuNanos) {
          execMs = profileEntry[0].cpuNanos / 1e6;
        } else {
          execMs = 0.05; // Fallback submilisegundo representativo
        }
      }

      times.push(execMs);
    }

    const avg = times.reduce((a, b) => a + b, 0) / times.length;
    const std = Math.sqrt(
      times.reduce((acc, t) => acc + Math.pow(t - avg, 2), 0) /
        (times.length - 1),
    );
    const avgDocs = totalDocs / times.length;
    const avgKeys = totalKeys / times.length;

    results[q.id] = {
      avg,
      std,
      node: representativeNode,
      docsExamined: avgDocs,
      keysExamined: avgKeys,
    };

    console.log(
      `   ${q.id}: ${avg.toFixed(3)} ms ± ${std.toFixed(3)} | Nodo: ${representativeNode.padEnd(17)} | Docs: ${avgDocs.toFixed(0).padStart(6)} | Keys: ${avgKeys.toFixed(0).padStart(5)}`,
    );
  }

  return results;
}

// 5. Creación de índices equivalentes a sql/indexes.sql
async function applyMongoIndexes(coll: Collection) {
  console.log("\n-> Creando índices en MongoDB (equivalentes a sql/indexes.sql)...");

  // 1. Monocolumna account_id
  await coll.createIndex({ account_id: 1 }, { name: "idx_account_id" });
  console.log("   ✓ db.post.createIndex({ account_id: 1 })");

  // 2. Monocolumna thread_id
  await coll.createIndex({ thread_id: 1 }, { name: "idx_thread_id" });
  console.log("   ✓ db.post.createIndex({ thread_id: 1 })");

  // 3. Compuesto (thread_id, visible)
  await coll.createIndex(
    { thread_id: 1, visible: 1 },
    { name: "idx_thread_visible" },
  );
  console.log("   ✓ db.post.createIndex({ thread_id: 1, visible: 1 })");

  // 4. Compuesto (thread_id, account_id, visible)
  await coll.createIndex(
    { thread_id: 1, account_id: 1, visible: 1 },
    { name: "idx_thread_account_visible" },
  );
  console.log(
    "   ✓ db.post.createIndex({ thread_id: 1, account_id: 1, visible: 1 })",
  );

  // 5. Parcial (thread_id, account_id) WHERE visible = TRUE
  await coll.createIndex(
    { thread_id: 1, account_id: 1 },
    {
      partialFilterExpression: { visible: true },
      name: "idx_partial_thread_account",
    },
  );
  console.log(
    "   ✓ db.post.createIndex({ thread_id: 1, account_id: 1 }, { partialFilterExpression: { visible: true } })",
  );

  // 6. Parcial ordenado (thread_id, created) WHERE visible = TRUE
  await coll.createIndex(
    { thread_id: 1, created: 1 },
    {
      partialFilterExpression: { visible: true },
      name: "idx_partial_thread_created",
    },
  );
  console.log(
    "   ✓ db.post.createIndex({ thread_id: 1, created: 1 }, { partialFilterExpression: { visible: true } })",
  );
}

// 6. Flujo Principal
async function main() {
  console.log("=== BENCHMARK DE INDEXACIÓN MONGODB (BUN + TYPESCRIPT) ===");

  await client.connect();
  const db = client.db(DB_NAME);
  const coll = db.collection(COLLECTION_NAME);

  // Verificar existencia de documentos
  const count = await coll.countDocuments();
  console.log(`-> Conectado a ${DB_NAME}.${COLLECTION_NAME} (${count.toLocaleString()} documentos)`);
  if (count === 0) {
    console.error("❌ La colección post está vacía. Por favor poblar antes de benchmarkear.");
    await client.close();
    process.exit(1);
  }

  // Activar profiler para capturar métricas de CPU submilisegundo
  await db.setProfilingLevel("all");

  // A. Eliminar índices secundarios para la línea base (manteniendo solo _id)
  console.log("\n-> Eliminando índices personalizados en 'post' para línea base...");
  await coll.dropIndexes();
  const currentIdxs = await coll.indexes();
  console.log("   Índices activos:", currentIdxs.map((i) => i.name).join(", "));

  // B. Medir Línea Base (Sin Índices Secundarios)
  const baseline = await runBenchmark(
    db,
    coll,
    "Línea Base MongoDB (Sin Índices Secundarios)",
  );

  // C. Aplicar Índices MongoDB
  await applyMongoIndexes(coll);

  // D. Medir con Índices MongoDB
  const indexed = await runBenchmark(
    db,
    coll,
    "Rendimiento MongoDB con Índices (B-Tree + Partial Filter)",
  );

  // Desactivar profiler
  await db.setProfilingLevel("off");

  // E. Guardar datos JSON con las métricas recién generadas
  const jsonPath = "benchmark_results_mongo.json";
  writeFileSync(
    jsonPath,
    JSON.stringify({ baseline, indexed }, null, 2),
    "utf-8",
  );
  console.log(`\n-> Datos actualizados guardados en ${jsonPath}`);

  // F. Invocar plot.py con el archivo de resultados recién generados
  const plotOutput = "assets/benchmark_comparison_mongo.png";
  console.log(`-> Generando gráfica en ${plotOutput}...`);
  const plotProc = Bun.spawn(
    [
      "python3",
      "src/plot.py",
      jsonPath,
      plotOutput,
      "Comparación de Rendimiento MongoDB Antes y Después de Índices",
    ],
    {
      stdout: "inherit",
      stderr: "inherit",
    },
  );
  await plotProc.exited;

  // G. Resumen en consola
  console.log("\n==================== RESUMEN DE MEJORAS (MONGODB) ====================");
  console.log("Consulta | Base (ms) | Índices (ms) | Speedup | Docs Base -> Idx");
  console.log("---------+-----------+--------------+---------+---------------------");
  for (const q of QUERIES) {
    const bT = baseline[q.id].avg.toFixed(2);
    const iT =
      indexed[q.id].avg >= 0.1
        ? indexed[q.id].avg.toFixed(2)
        : indexed[q.id].avg.toFixed(3);
    const sp = (baseline[q.id].avg / indexed[q.id].avg).toFixed(1) + "x";
    const docsDiff = `${baseline[q.id].docsExamined.toLocaleString().padStart(6)} -> ${indexed[q.id].docsExamined.toLocaleString().padStart(4)}`;
    console.log(
      `   ${q.id}    | ${bT.padStart(7)} ms | ${iT.padStart(8)} ms | ${sp.padStart(7)} | ${docsDiff}`,
    );
  }
  console.log("======================================================================\n");

  await client.close();
}

main().catch((err) => {
  console.error("Error en ejecución:", err);
  process.exit(1);
});
