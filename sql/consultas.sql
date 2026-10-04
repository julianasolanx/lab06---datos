-- Q1
EXPLAIN ANALYZE
SELECT post_id, thread_id, account_id, created, visible, comment
FROM post
WHERE account_id = 1;

-- Q2
EXPLAIN ANALYZE
SELECT COUNT(*) AS total_posts
FROM post
WHERE account_id = 1;

-- Q3
EXPLAIN ANALYZE
SELECT post_id, thread_id, account_id, created, comment
FROM post
WHERE thread_id = 1
  AND visible = TRUE;

-- Q4
EXPLAIN ANALYZE
SELECT COUNT(*) AS total_posts
FROM post
WHERE account_id = 1
  AND thread_id = 1;

-- Q5
EXPLAIN ANALYZE
SELECT post_id, thread_id, account_id, created, comment
FROM post
WHERE thread_id = 1
  AND visible = TRUE
  AND created >= date_trunc('month', CURRENT_TIMESTAMP)
  AND created < date_trunc('month', CURRENT_TIMESTAMP) + INTERVAL '1 month'
ORDER BY created ASC;
