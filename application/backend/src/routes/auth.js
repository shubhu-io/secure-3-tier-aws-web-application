import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { Router } from "express";

export default function authRouter({ db, jwtSecret, jwtExpiresIn }) {
  const router = Router();

  // if db isn't ready yet, return 503 for all auth routes
  if (!db) {
    router.use((req, res) =>
      res.status(503).json({ error: "Database not configured" })
    );
    return router;
  }

  // register a new user
  router.post("/register", async (req, res, next) => {
    try {
      const { email, password } = req.body || {};

      if (!email || !password) {
        return res.status(400).json({ error: "email and password are required" });
      }
      if (password.length < 8) {
        return res.status(400).json({ error: "password must be at least 8 characters" });
      }

      const normalizedEmail = String(email).toLowerCase().trim();
      const hash = await bcrypt.hash(password, 12);

      const [result] = await db.query(
        "INSERT INTO users (email, password) VALUES (?, ?)",
        [normalizedEmail, hash]
      );

      const userId = result.insertId;
      const [rows] = await db.query("SELECT id, email, created_at FROM users WHERE id = ?", [userId]);
      const user = rows[0];
      const token = jwt.sign({ sub: user.id, email: user.email }, jwtSecret, {
        expiresIn: jwtExpiresIn,
      });

      res.status(201).json({ token, user });
    } catch (err) {
      // ER_DUP_ENTRY = unique constraint violation, means email already exists
      if (err.code === "ER_DUP_ENTRY") {
        return res.status(409).json({ error: "email already registered" });
      }
      next(err);
    }
  });

  // login
  router.post("/login", async (req, res, next) => {
    try {
      const { email, password } = req.body || {};

      if (!email || !password) {
        return res.status(400).json({ error: "email and password are required" });
      }

      const normalizedEmail = String(email).toLowerCase().trim();
      const [rows] = await db.query("SELECT * FROM users WHERE email = ?", [normalizedEmail]);

      if (rows.length === 0) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      const user = rows[0];
      const valid = await bcrypt.compare(password, user.password);

      if (!valid) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      const token = jwt.sign({ sub: user.id, email: user.email }, jwtSecret, {
        expiresIn: jwtExpiresIn,
      });

      res.json({ token, user: { id: user.id, email: user.email } });
    } catch (err) {
      next(err);
    }
  });

  return router;
}
