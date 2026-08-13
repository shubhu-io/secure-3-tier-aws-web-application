import { Router } from "express";
import { requireAuth } from "../middleware/auth.js";

export default function itemsRouter({ db, jwtSecret }) {
  const router = Router();

  if (!db) {
    router.use((req, res) =>
      res.status(503).json({ error: "Database not configured" })
    );
    return router;
  }

  router.use(requireAuth(jwtSecret));

  // GET /api/items - list current user's items
  router.get("/", async (req, res, next) => {
    try {
      const result = await db.query(
        "SELECT id, title, description, created_at FROM items WHERE user_id = $1 ORDER BY created_at DESC",
        [req.userId]
      );
      res.json({ items: result.rows });
    } catch (err) {
      next(err);
    }
  });

  // POST /api/items  { title, description }
  router.post("/", async (req, res, next) => {
    try {
      const { title, description } = req.body || {};

      if (!title) {
        return res.status(400).json({ error: "title is required" });
      }

      const result = await db.query(
        "INSERT INTO items (user_id, title, description) VALUES ($1, $2, $3) RETURNING id, title, description, created_at",
        [req.userId, title, description || null]
      );

      res.status(201).json({ item: result.rows[0] });
    } catch (err) {
      next(err);
    }
  });

  // DELETE /api/items/:id - delete own item
  router.delete("/:id", async (req, res, next) => {
    try {
      const result = await db.query(
        "DELETE FROM items WHERE id = $1 AND user_id = $2 RETURNING id",
        [req.params.id, req.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: "item not found" });
      }

      res.json({ deleted: result.rows[0].id });
    } catch (err) {
      next(err);
    }
  });

  return router;
}
