CREATE TABLE IF NOT EXISTS app_info (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO app_info (name)
VALUES ('PostgreSQL works in Docker Compose');