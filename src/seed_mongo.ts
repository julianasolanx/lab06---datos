import { MongoClient } from "mongodb";
import { readFileSync, existsSync } from "fs";
import { SQL } from "bun";

const MONGO_URL =
  process.env.MONGO_URL || "mongodb://acha:acha@tally:27017/?authSource=admin";
const PG_URL =
  process.env.DATABASE_URL || "postgres://acha:acha@100.117.32.119:5555/lab6";
const DB_NAME = process.env.MONGO_DB || "lab6";

const args = process.argv.slice(2);
const cloneFromPg = args.includes("--from-pg");

async function main() {
  console.log("=== POBLADO DE BASE DE DATOS MONGODB ===");
  console.log(`Conectando a MongoDB: ${MONGO_URL} (${DB_NAME})...`);

  const client = new MongoClient(MONGO_URL);
  await client.connect();
  const db = client.db(DB_NAME);

  if (cloneFromPg) {
    console.log(`\nModo: Clonar datos directamente desde PostgreSQL (${PG_URL})...`);
    const pg = new SQL(PG_URL);

    try {
      console.time("⏱ Tiempo total de sincronización");

      // 1. Cuentas
      console.log("-> Sincronizando tabla 'account'...");
      const accounts = await pg`SELECT account_id, name, dob FROM account`;
      const accColl = db.collection("account");
      await accColl.drop().catch(() => {});
      if (accounts.length > 0) {
        await accColl.insertMany(accounts);
      }
      console.log(`   ✓ ${accounts.length} cuentas importadas.`);

      // 2. Hilos
      console.log("-> Sincronizando tabla 'thread'...");
      const threads = await pg`SELECT thread_id, account_id, title FROM thread`;
      const threadColl = db.collection("thread");
      await threadColl.drop().catch(() => {});
      if (threads.length > 0) {
        await threadColl.insertMany(threads);
      }
      console.log(`   ✓ ${threads.length} hilos importados.`);

      // 3. Posts
      console.log("-> Sincronizando tabla 'post' (100.000 filas)...");
      const posts = await pg`SELECT post_id, thread_id, account_id, created, visible, comment FROM post`;
      const postColl = db.collection("post");
      await postColl.drop().catch(() => {});

      const docs = posts.map((p: any) => ({
        ...p,
        created: new Date(p.created),
      }));

      const batchSize = 10000;
      for (let i = 0; i < docs.length; i += batchSize) {
        await postColl.insertMany(docs.slice(i, i + batchSize), { ordered: false });
      }
      console.log(`   ✓ ${docs.length} posts importados.`);

      console.timeEnd("⏱ Tiempo total de sincronización");
      await pg.close();
    } catch (err: any) {
      console.error("❌ Error clonando desde PostgreSQL:", err.message);
      console.log("-> Se procederá con la generación sintética local autónoma...");
      await generateStandalone(db);
    }
  } else {
    console.log("\nModo: Generación sintética autónoma (equivalente a sql/random.sql)...");
    await generateStandalone(db);
  }

  await client.close();
  console.log("\n✓ Proceso completado exitosamente.");
}

async function generateStandalone(db: any) {
  const wordsPath = "resources/words.txt";
  if (!existsSync(wordsPath)) {
    throw new Error(`Archivo ${wordsPath} no encontrado.`);
  }

  const words = readFileSync(wordsPath, "utf-8")
    .split(/\r?\n/)
    .map((w) => w.trim())
    .filter(Boolean);

  console.log(`-> Diccionario cargado: ${words.length} palabras.`);

  function randomWord() {
    return words[Math.floor(Math.random() * words.length)];
  }

  function randomSentence(n: number) {
    const list: string[] = [];
    for (let i = 0; i < n; i++) list.push(randomWord());
    return list.join(" ");
  }

  function initCap(str: string) {
    return str
      .split(" ")
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(" ");
  }

  console.time("⏱ Tiempo de generación");

  // 1. Cuentas
  console.log("-> Generando 100 cuentas en db.account...");
  const vowels = "aeiou";
  const consonants = "bcdfghjklmnpqrstvwxyz";
  const accounts = [];
  for (let i = 1; i <= 100; i++) {
    const name =
      vowels[Math.floor(Math.random() * vowels.length)].toUpperCase() +
      consonants[Math.floor(Math.random() * consonants.length)] +
      consonants[Math.floor(Math.random() * consonants.length)] +
      vowels[Math.floor(Math.random() * vowels.length)] +
      consonants[Math.floor(Math.random() * consonants.length)] +
      consonants[Math.floor(Math.random() * consonants.length)] +
      vowels[Math.floor(Math.random() * vowels.length)];
    const dob = new Date(Date.now() + Math.random() * 365 * 86400000);
    accounts.push({ account_id: i, name, dob });
  }
  const accColl = db.collection("account");
  await accColl.drop().catch(() => {});
  await accColl.insertMany(accounts);

  // 2. Hilos
  console.log("-> Generando 1.000 hilos en db.thread...");
  const threads = [];
  for (let i = 1; i <= 1000; i++) {
    threads.push({
      thread_id: i,
      account_id: Math.floor(Math.random() * 100) + 1,
      title: initCap(randomSentence(5)),
    });
  }
  const threadColl = db.collection("thread");
  await threadColl.drop().catch(() => {});
  await threadColl.insertMany(threads);

  // 3. Posts
  console.log("-> Generando 100.000 posts en db.post...");
  const postColl = db.collection("post");
  await postColl.drop().catch(() => {});

  const totalPosts = 100000;
  const batchSize = 10000;
  let postCounter = 1;

  for (let b = 0; b < totalPosts; b += batchSize) {
    const batch = [];
    for (let i = 0; i < batchSize; i++) {
      batch.push({
        post_id: postCounter++,
        thread_id: Math.floor(Math.random() * 1000) + 1,
        account_id: Math.floor(Math.random() * 100) + 1,
        created: new Date(Date.now() - Math.random() * 1000 * 86400000),
        visible: Math.random() > 0.1,
        comment: randomSentence(20),
      });
    }
    await postColl.insertMany(batch, { ordered: false });
  }

  console.timeEnd("⏱ Tiempo de generación");
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
