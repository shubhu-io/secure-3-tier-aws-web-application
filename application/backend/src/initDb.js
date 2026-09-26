const SCHEMA = `
CREATE TABLE IF NOT EXISTS users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  email       VARCHAR(255) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS items (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_items_user_id ON items(user_id);
`;

export async function initDb(pool) {
  // MySQL requires multipleStatements: true for running multiple queries at once,
  // or we can just split and execute them sequentially.
  const queries = SCHEMA.split(';').map(q => q.trim()).filter(q => q.length > 0);
  for (const query of queries) {
    try {
      await pool.query(query);
    } catch (e) {
      if (e.code !== 'ER_DUP_KEYNAME') { // ignore index exists error
        throw e;
      }
    }
  }
}
