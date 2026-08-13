import { Router } from "express";

export default function healthRouter(db) {
  const router = Router();

  router.get("/", async (req, res) => {
    let dbStatus = "disconnected";

    if (db) {
      try {
        await db.query("SELECT 1");
        dbStatus = "connected";
      } catch {
        dbStatus = "disconnected";
      }
    }

    // Always 200 so the ALB health check never flaps on transient DB issues.
    // Use /api/ready for a strict readiness signal.
    res.json({
      status: "ok",
      db: dbStatus,
      uptime: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    });
  });

  router.get("/ready", async (req, res) => {
    if (!db) {
      return res.status(503).json({ status: "not ready", db: "disconnected" });
    }

    try {
      await db.query("SELECT 1");
      return res.json({ status: "ready", db: "connected" });
    } catch {
      return res.status(503).json({ status: "not ready", db: "disconnected" });
    }
  });

  return router;
}
