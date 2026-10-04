// Consultas de negocio con EXPLAIN (equivalente a sql/consultas.sql)
// Uso: mongosh "mongodb://acha:acha@tally:27017/lab6?authSource=admin" mongo/consultas.js

db = db.getSiblingDB("lab6");

const now = new Date();
const startOfMonth = new Date(
  Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
);
const endOfMonth = new Date(
  Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
);

print("\n--- Q1: Posts Usuario (account_id = 1) ---");
printjson(
  db.post
    .find(
      { account_id: 1 },
      {
        post_id: 1,
        thread_id: 1,
        account_id: 1,
        created: 1,
        visible: 1,
        comment: 1,
        _id: 0,
      },
    )
    .explain("executionStats").executionStats,
);

print("\n--- Q2: Count Usuario (account_id = 1) ---");
printjson(
  db.post
    .aggregate([{ $match: { account_id: 1 } }, { $count: "total_posts" }])
    .explain("executionStats").stages[0].$cursor.executionStats,
);

print("\n--- Q3: Thread Visible (thread_id = 1, visible = true) ---");
printjson(
  db.post
    .find(
      { thread_id: 1, visible: true },
      {
        post_id: 1,
        thread_id: 1,
        account_id: 1,
        created: 1,
        comment: 1,
        _id: 0,
      },
    )
    .explain("executionStats").executionStats,
);

print("\n--- Q4: Count Hilo+User (account_id = 1, thread_id = 1) ---");
printjson(
  db.post
    .aggregate([
      { $match: { account_id: 1, thread_id: 1 } },
      { $count: "total_posts" },
    ])
    .explain("executionStats").stages[0].$cursor.executionStats,
);

print(
  "\n--- Q5: Thread Mes Ord (thread_id = 1, visible = true, ordenado por fecha) ---",
);
printjson(
  db.post
    .find(
      {
        thread_id: 1,
        visible: true,
        created: { $gte: startOfMonth, $lt: endOfMonth },
      },
      {
        post_id: 1,
        thread_id: 1,
        account_id: 1,
        created: 1,
        comment: 1,
        _id: 0,
      },
    )
    .sort({ created: 1 })
    .explain("executionStats").executionStats,
);
