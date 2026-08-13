import config from "./config.js";
import pool from "./db.js";
import { initDb } from "./initDb.js";
import { createApp } from "./app.js";

async function start() {
  // Create tables if they do not exist yet (simple, idempotent migration)
  try {
    await initDb(pool);
  } catch (err) {
    console.error("Database init failed (continuing - health check will report it):", err.message);
  }

  const app = createApp({
    db: pool,
    jwtSecret: config.jwt.secret,
    jwtExpiresIn: config.jwt.expiresIn,
  });

  app.listen(config.port, () => {
    console.log(`[${new Date().toISOString()}] backend listening on :${config.port} (${config.nodeEnv})`);
  });
}

start().catch((err) => {
  console.error("Fatal startup error:", err);
  process.exit(1);
});
