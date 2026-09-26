import express from "express";
import healthRouter from "./routes/health.js";
import authRouter from "./routes/auth.js";
import itemsRouter from "./routes/items.js";

// factory fn so tests can inject a fake db
export function createApp(deps = {}) {
  const app = express();

  const db = deps.db ?? null;
  const jwtSecret = deps.jwtSecret ?? "";
  const jwtExpiresIn = deps.jwtExpiresIn ?? "8h";

  app.use(express.json());

  // hide default x-powered-by header, add our own
  app.use((req, res, next) => {
    res.set("X-Powered-By", "secure-ntier-backend");
    next();
  });

  app.use("/health", healthRouter(db));
  app.use("/api/auth", authRouter({ db, jwtSecret, jwtExpiresIn }));
  app.use("/api/items", itemsRouter({ db, jwtSecret }));

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({ error: "Not found" });
  });

  // generic error handler - logs it and returns 500
  app.use((err, req, res, next) => {
    console.error("unhandled error:", err);
    res.status(500).json({ error: "Internal server error" });
  });

  return app;
}
