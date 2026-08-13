import { test } from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/app.js";

async function startServer(app) {
  const server = app.listen(0);
  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();
  return { server, base: `http://127.0.0.1:${port}` };
}

export { test, assert, startServer, createApp };
