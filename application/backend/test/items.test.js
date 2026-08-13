import jwt from "jsonwebtoken";
import { test, assert, startServer, createApp } from "./helpers.js";

const db = {
  query: async (sql) => {
    if (sql.includes("FROM items WHERE user_id")) {
      return { rows: [{ id: 2, title: "task 1", description: null, created_at: "2026-01-01" }] };
    }
    if (sql.includes("INSERT INTO items")) {
      return { rows: [{ id: 3, title: "new task", description: "d", created_at: "2026-01-01" }] };
    }
    if (sql.includes("DELETE FROM items")) {
      return { rows: [{ id: 1 }] };
    }
    return { rows: [] };
  },
};

function authedFetch(base, path, token, init = {}) {
  return fetch(`${base}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(init.headers || {}),
    },
  });
}

const token = jwt.sign({ sub: 1, email: "user@test.com" }, "test-secret", { expiresIn: "1h" });

test("items requires authentication", async () => {
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/items`);

  assert.equal(res.status, 401);

  server.close();
});

test("rejects a tampered token", async () => {
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const bad = jwt.sign({ sub: 1 }, "wrong-secret");
  const res = await authedFetch(base, "/api/items", bad);

  assert.equal(res.status, 401);

  server.close();
});

test("lists the user's items", async () => {
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await authedFetch(base, "/api/items", token);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.items.length, 1);
  assert.equal(body.items[0].title, "task 1");

  server.close();
});

test("creates an item", async () => {
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await authedFetch(base, "/api/items", token, {
    method: "POST",
    body: JSON.stringify({ title: "new task", description: "d" }),
  });
  const body = await res.json();

  assert.equal(res.status, 201);
  assert.equal(body.item.title, "new task");

  server.close();
});

test("deletes an item", async () => {
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await authedFetch(base, "/api/items/1", token, { method: "DELETE" });
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.deleted, 1);

  server.close();
});
