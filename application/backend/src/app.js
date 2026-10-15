import express from "express";
import healthRouter from "./routes/health.js";
import authRouter from "./routes/auth.js";
import itemsRouter from "./routes/items.js";

// factory fn so tests can inject a fake db
export function createApp(deps = {}) {
  const app = express();

  // Behind ALB + nginx: trust first proxy for correct req.ip / X-Forwarded-*
  app.set("trust proxy", 1);

  const db = deps.db ?? null;
  const jwtSecret = deps.jwtSecret ?? "";
  const jwtExpiresIn = deps.jwtExpiresIn ?? "8h";

  app.use(express.json());

  // minimal Prometheus metrics (zero-dependency) for monitoring/prometheus
  const metrics = { http_requests_total: 0 };
  app.use((req, res, next) => {
    metrics.http_requests_total += 1;
    next();
  });
  app.get("/metrics", (req, res) => {
    res.type("text/plain; version=0.0.4").send(
      `# HELP http_requests_total Total HTTP requests\n` +
        `# TYPE http_requests_total counter\n` +
        `http_requests_total ${metrics.http_requests_total}\n` +
        `# HELP process_uptime_seconds Process uptime\n` +
        `# TYPE process_uptime_seconds gauge\n` +
        `process_uptime_seconds ${Math.round(process.uptime())}\n`
    );
  });

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
