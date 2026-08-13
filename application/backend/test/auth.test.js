import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { test, assert, startServer, createApp } from "./helpers.js";

const hash = await bcrypt.hash("password123", 4);

function fakeDb(overrides = {}) {
  return {
    query: async (sql, params) => {
      if (sql.includes("INSERT INTO users")) {
        return {
          rows: [{ id: 1, email: params[0], created_at: new Date().toISOString() }],
        };
      }
      if (sql.includes("SELECT * FROM users")) {
        return {
          rows: [{ id: 1, email: params[0], password: hash }],
        };
      }
      return { rows: [] };
    },
    ...overrides,
  };
}

test("register creates a user and returns a JWT", async () => {
  const app = createApp({ db: fakeDb(), jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "User@Test.com", password: "password123" }),
  });
  const body = await res.json();

  assert.equal(res.status, 201);
  assert.ok(body.token);
  assert.equal(body.user.email, "user@test.com"); // normalized to lowercase

  const payload = jwt.verify(body.token, "test-secret");
  assert.equal(payload.sub, 1);

  server.close();
});

test("register rejects short passwords", async () => {
  const app = createApp({ db: fakeDb(), jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "a@b.com", password: "short" }),
  });

  assert.equal(res.status, 400);

  server.close();
});

test("login returns a token with valid credentials", async () => {
  const app = createApp({ db: fakeDb(), jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "user@test.com", password: "password123" }),
  });
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.ok(body.token);

  server.close();
});

test("login returns 401 with wrong password", async () => {
  const app = createApp({ db: fakeDb(), jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "user@test.com", password: "wrong-password" }),
  });

  assert.equal(res.status, 401);

  server.close();
});

test("duplicate email returns 409", async () => {
  const db = fakeDb({
    query: async () => {
      const err = new Error("duplicate key");
      err.code = "23505";
      throw err;
    },
  });
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/api/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "a@b.com", password: "password123" }),
  });

  assert.equal(res.status, 409);

  server.close();
});
