// Script para poblar MongoDB de forma autónoma desde mongosh
// Uso: mongosh "mongodb://acha:acha@tally:27017/lab6?authSource=admin" mongo/seed.js

const fs = require("fs");
const path = require("path");

db = db.getSiblingDB("lab6");

print("=== POBLANDO BASE DE DATOS MONGODB (lab6) ===");

// 1. Cargar diccionario de palabras
const wordsPath = path.resolve("resources/words.txt");
if (!fs.existsSync(wordsPath)) {
  print("❌ No se encontró resources/words.txt");
  quit(1);
}
const words = fs
  .readFileSync(wordsPath, "utf-8")
  .split(/\r?\n/)
  .map((w) => w.trim())
  .filter(Boolean);

print(`✓ Cargadas ${words.length} palabras de ${wordsPath}`);

function randomWord() {
  return words[Math.floor(Math.random() * words.length)];
}

function randomSentence(n) {
  const res = [];
  for (let i = 0; i < n; i++) res.push(randomWord());
  return res.join(" ");
}

function initCap(str) {
  return str
    .split(" ")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

// 2. Crear 100 Cuentas (account)
print("\n-> Generando 100 cuentas en db.account...");
db.account.drop();
const accounts = [];
const vowels = "aeiou";
const consonants = "bcdfghjklmnpqrstvwxyz";

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
db.account.insertMany(accounts);
print(`✓ ${db.account.countDocuments()} cuentas creadas.`);

// 3. Crear 1.000 Hilos (thread)
print("\n-> Generando 1.000 hilos en db.thread...");
db.thread.drop();
const threads = [];
for (let i = 1; i <= 1000; i++) {
  threads.push({
    thread_id: i,
    account_id: Math.floor(Math.random() * 100) + 1,
    title: initCap(randomSentence(5)),
  });
}
db.thread.insertMany(threads);
print(`✓ ${db.thread.countDocuments()} hilos creados.`);

// 4. Crear 100.000 Publicaciones (post)
print("\n-> Generando 100.000 posts en db.post (en lotes de 10.000)...");
db.post.drop();

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
  db.post.insertMany(batch, { ordered: false });
  print(`   Insertados ${Math.min(b + batchSize, totalPosts)} / ${totalPosts}...`);
}

print(`\n✓ Colección db.post lista con ${db.post.countDocuments()} documentos.`);
print("=== BASE DE DATOS POBLADA EXITOSAMENTE ===");
