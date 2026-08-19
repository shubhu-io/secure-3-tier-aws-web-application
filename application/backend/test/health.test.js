import { test, assert, startServer, createApp } from "./helpers.js";

test("GET /health returns ok with db connected", async () => {
  const db = { query: async () => ({ rows: [] }) };
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/health`);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.status, "ok");
  assert.equal(body.db, "connected");

  server.close();
});

test("GET /health returns ok but db disconnected when db is down", async () => {
  const db = { query: async () => { throw new Error("db down"); } };
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/health`);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.db, "disconnected");

  server.close();
});

test("GET /health works without a database at all", async () => {
  const app = createApp({ jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/health`);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.status, "ok");
  assert.equal(body.db, "disconnected");

  server.close();
});

test("GET /health/ready returns 503 when db is down", async () => {
  const db = { query: async () => { throw new Error("db down"); } };
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/health/ready`);

  assert.equal(res.status, 503);

  server.close();
});

test("GET /health/ready returns 200 when db is connected", async () => {
  const db = { query: async () => ({ rows: [] }) };
  const app = createApp({ db, jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/health/ready`);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.status, "ready");
  assert.equal(body.db, "connected");

  server.close();
});

test("unknown routes return 404 JSON", async () => {
  const app = createApp({ jwtSecret: "test-secret" });
  const { server, base } = await startServer(app);

  const res = await fetch(`${base}/does-not-exist`);

  assert.equal(res.status, 404);

  server.close();
});
