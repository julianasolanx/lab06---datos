// MongoDB Indexing Script (equivalente a sql/indexes.sql)
// Uso: mongosh "mongodb://acha:acha@tally:27017/lab6?authSource=admin" mongo/indexes.js

db = db.getSiblingDB("lab6");

print("=== Creando Índices en MongoDB (colección: post) ===");

// 1. Índice Monocolumna en account_id
// Equivalente a: CREATE INDEX ON post (account_id);
db.post.createIndex({ account_id: 1 }, { name: "idx_account_id" });
print("✓ Creado idx_account_id: { account_id: 1 }");

// 2. Índice Monocolumna en thread_id
// Equivalente a: CREATE INDEX ON post (thread_id);
db.post.createIndex({ thread_id: 1 }, { name: "idx_thread_id" });
print("✓ Creado idx_thread_id: { thread_id: 1 }");

// 3. Índice Compuesto en (thread_id, visible)
// Equivalente a: CREATE INDEX ON post (thread_id, visible);
db.post.createIndex(
  { thread_id: 1, visible: 1 },
  { name: "idx_thread_visible" },
);
print("✓ Creado idx_thread_visible: { thread_id: 1, visible: 1 }");

// 4. Índice Compuesto en (thread_id, account_id, visible)
// Equivalente a: CREATE INDEX ON post (thread_id, account_id, visible);
db.post.createIndex(
  { thread_id: 1, account_id: 1, visible: 1 },
  { name: "idx_thread_account_visible" },
);
print(
  "✓ Creado idx_thread_account_visible: { thread_id: 1, account_id: 1, visible: 1 }",
);

// 5. Índice Parcial en (thread_id, account_id) WHERE visible = TRUE
// Equivalente a: CREATE INDEX ON post (thread_id, account_id) WHERE visible = TRUE;
db.post.createIndex(
  { thread_id: 1, account_id: 1 },
  {
    partialFilterExpression: { visible: true },
    name: "idx_partial_thread_account",
  },
);
print(
  "✓ Creado idx_partial_thread_account: { thread_id: 1, account_id: 1 } (visible: true)",
);

// 6. Índice Parcial con Ordenamiento en (thread_id, created) WHERE visible = TRUE
// Equivalente a: CREATE INDEX ON post (thread_id, created) WHERE visible = TRUE;
db.post.createIndex(
  { thread_id: 1, created: 1 },
  {
    partialFilterExpression: { visible: true },
    name: "idx_partial_thread_created",
  },
);
print(
  "✓ Creado idx_partial_thread_created: { thread_id: 1, created: 1 } (visible: true)",
);

print("\nÍndices registrados en db.post:");
printjson(db.post.getIndexes());
