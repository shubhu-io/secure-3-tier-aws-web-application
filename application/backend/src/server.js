import config from "./config.js";
import pool from "./db.js";
import { initDb } from "./initDb.js";
import { createApp } from "./app.js";

async function start() {
  // On EC2 first boot RDS/SG may lag behind the app - retry migrations
  // instead of serving a permanently degraded API until the next restart.
  const attempts = Number(process.env.DB_INIT_RETRIES ?? 12);
  const delayMs = Number(process.env.DB_INIT_RETRY_MS ?? 10000);
  for (let i = 1; i <= attempts; i++) {
    try {
      await initDb(pool);
      break;
    } catch (err) {
      console.error(`db init attempt ${i}/${attempts} failed:`, err.message);
      if (i === attempts) {
        console.error("db init failed, continuing anyway (API will 503 until DB is reachable)");
      } else {
        await new Promise((r) => setTimeout(r, delayMs));
      }
    }
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
