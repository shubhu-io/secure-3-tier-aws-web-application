import express from "express";
import healthRouter from "./routes/health.js";
import authRouter from "./routes/auth.js";
import itemsRouter from "./routes/items.js";

/**
 * Application factory. `deps` allows tests to inject a fake database and a
 * fixed JWT secret. In production server.js passes the real pool.
 */
export function createApp(deps = {}) {
  const app = express();

  const db = deps.db ?? null;
  const jwtSecret = deps.jwtSecret ?? "";
  const jwtExpiresIn = deps.jwtExpiresIn ?? "8h";

  app.use(express.json());

  app.use((req, res, next) => {
    res.set("X-Powered-By", "secure-ntier-backend");
    next();
  });

  app.use("/health", healthRouter(db));
  app.use("/api/auth", authRouter({ db, jwtSecret, jwtExpiresIn }));
  app.use("/api/items", itemsRouter({ db, jwtSecret }));

  app.use((req, res) => {
    res.status(404).json({ error: "Not found" });
  });

  app.use((err, req, res, next) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ error: "Internal server error" });
  });

  return app;
}
