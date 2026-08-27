import { createServer } from 'http';
import { test } from 'node:test';
import assert from 'node:assert';

const BASE = 'http://127.0.0.1:3000';

let server;

const startServer = (done) => {
  server = createServer(async (req, res) => {
    const url = new URL(req.url, BASE);
    const path = url.pathname;

    if (req.method === 'GET' && path === '/') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Welcome' }));
    } else if (req.method === 'GET' && path === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'healthy' }));
    } else if (req.method === 'GET' && path === '/items') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items: [] }));
    } else if (req.method === 'POST' && path === '/items') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try {
          const newItem = JSON.parse(body);
          if (!newItem.name) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'name is required' }));
          } else {
            res.writeHead(201, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ id: 'item-1', name: newItem.name }));
          }
        } catch {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid JSON' }));
        }
      });
    } else if (req.method === 'DELETE' && path === '/items') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ removed: true }));
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Not found' }));
    }
  });
  server.listen(3000, done);
};

const stopServer = (done) => {
  if (server) {
    server.close(done);
  }
};

test('GET / returns welcome message', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/`);
    const data = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(data.message, 'Welcome');
  } finally {
    stopServer(() => {});
  }
});

test('GET /health returns healthy', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/health`);
    const data = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(data.status, 'healthy');
  } finally {
    stopServer(() => {});
  }
});

test('GET /items returns empty items', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/items`);
    const data = await res.json();
    assert.strictEqual(res.status, 200);
    assert.deepStrictEqual(data.items, []);
  } finally {
    stopServer(() => {});
  }
});

test('POST /items with valid name', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'widget' }),
    });
    const data = await res.json();
    assert.strictEqual(res.status, 201);
    assert.strictEqual(data.name, 'widget');
  } finally {
    stopServer(() => {});
  }
});

test('POST /items without name returns 400', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    const data = await res.json();
    assert.strictEqual(res.status, 400);
    assert.strictEqual(data.error, 'name is required');
  } finally {
    stopServer(() => {});
  }
});

test('DELETE /items clears items', async () => {
  const srv = await new Promise(resolve => startServer(resolve));
  try {
    const fetch = (await import('node:fetch')).default;
    const res = await fetch(`${BASE}/items`, { method: 'DELETE' });
    const data = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(data.removed, true);
  } finally {
    stopServer(() => {});
  }
});