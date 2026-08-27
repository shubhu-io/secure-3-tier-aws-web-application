import { createServer } from 'http';

const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '0.0.0.0';

let items: Array<{ id: string; name: string }> = [];

function sendJson(res: NodeJS.WritableStream, statusCode: number, data: unknown) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': body.length,
    'Cache-Control': 'no-cache',
  });
  res.end(body);
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;

  if (req.method === 'GET' && path === '/') {
    sendJson(res, 200, { message: 'Welcome to the TypeScript HTTP server' });
    return;
  }

  if (req.method === 'GET' && path === '/health') {
    sendJson(res, 200, { status: 'healthy' });
    return;
  }

  if (req.method === 'GET' && path === '/items') {
    sendJson(res, 200, { items });
    return;
  }

  if (req.method === 'POST' && path === '/items') {
    let body = '';
    req.on('data', (chunk: string) => { body += chunk; });
    req.on('end', () => {
      try {
        const newItem = JSON.parse(body);
        if (!newItem.name) {
          sendJson(res, 400, { error: 'name is required' });
          return;
        }
        const item: { id: string; name: string } = {
          id: `item-${Date.now()}`,
          name: newItem.name,
        };
        items.push(item);
        sendJson(res, 201, item);
      } catch {
        sendJson(res, 400, { error: 'Invalid JSON' });
      }
    });
    return;
  }

  if (req.method === 'DELETE' && path === '/items') {
    items = [];
    sendJson(res, 200, { removed: true });
    return;
  }

  sendJson(res, 404, { error: 'Not found' });
});

server.listen(PORT, HOST, () => {
  console.log(`TypeScript HTTP server running at http://${HOST}:${PORT}/`);
});