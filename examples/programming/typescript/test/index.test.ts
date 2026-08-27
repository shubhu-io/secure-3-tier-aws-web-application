import { createServer } from 'http';

const BASE = 'http://127.0.0.1:3000';

let server: NodeJS.Server;

beforeAll((done) => {
  const s = server = createServer(async (req, res) => {
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
      req.on('data', (chunk: string) => { body += chunk; });
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
  s.listen(3000, done);
});

afterAll((done) => {
  server.close(done);
});

test('GET / returns welcome message', async () => {
  const res = await fetch(`${BASE}/`);
  const data = await res.json();
  expect(res.status).toBe(200);
  expect(data.message).toBe('Welcome');
});

test('GET /health returns healthy', async () => {
  const res = await fetch(`${BASE}/health`);
  const data = await res.json();
  expect(res.status).toBe(200);
  expect(data.status).toBe('healthy');
});

test('GET /items returns empty items', async () => {
  const res = await fetch(`${BASE}/items`);
  const data = await res.json();
  expect(res.status).toBe(200);
  expect(data.items).toEqual([]);
});

test('POST /items with valid name', async () => {
  const res = await fetch(`${BASE}/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'widget' }),
  });
  const data = await res.json();
  expect(res.status).toBe(201);
  expect(data.name).toBe('widget');
});

test('POST /items without name returns 400', async () => {
  const res = await fetch(`${BASE}/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  const data = await res.json();
  expect(res.status).toBe(400);
  expect(data.error).toBe('name is required');
});

test('DELETE /items clears items', async () => {
  const res = await fetch(`${BASE}/items`, { method: 'DELETE' });
  const data = await res.json();
  expect(res.status).toBe(200);
  expect(data.removed).toBe(true);
});