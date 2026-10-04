CREATE INDEX ON post (account_id);

CREATE INDEX ON post (thread_id);

CREATE INDEX ON post (thread_id, visible);

CREATE INDEX ON post (thread_id, account_id, visible);

CREATE INDEX ON post (thread_id, account_id)
  WHERE visible = TRUE;

CREATE INDEX ON post (thread_id, created)
  WHERE visible = TRUE;
