DROP TABLE IF EXISTS words CASCADE;

CREATE TABLE words (word TEXT);
COPY words(word) FROM '/temp/words.txt';
