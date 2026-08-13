import jwt from "jsonwebtoken";

export function requireAuth(jwtSecret) {
  return (req, res, next) => {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ error: "missing token" });
    }

    try {
      const payload = jwt.verify(token, jwtSecret);
      req.userId = payload.sub;
      return next();
    } catch {
      return res.status(401).json({ error: "invalid or expired token" });
    }
  };
}
