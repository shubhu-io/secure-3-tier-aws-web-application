import config from "./config.js";
import pool from "./db.js";
import { initDb } from "./initDb.js";
import { createApp } from "./app.js";

async function start() {
  // run db migrations first, but don't crash if db is slow to start
  try {
    await initDb(pool);
  } catch (err) {
    console.error("db init failed, continuing anyway:", err.message);
  }

  const app = createApp({
    db: pool,
    jwtSecret: config.jwt.secret,
    jwtExpiresIn: config.jwt.expiresIn,
  });

  app.listen(config.port, () => {
    console.log(`server started on port ${config.port} (${config.nodeEnv})`);
  });
}

start().catch((err) => {
  console.error("startup failed:", err);
  process.exit(1);
});
