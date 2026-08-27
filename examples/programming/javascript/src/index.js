import { createServer } from 'http';

const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '0.0.0.0';

let items = [];

function sendJson(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': body.length,
    'Cache-Control': 'no-cache',
  });
  res.end(body);
}

function handleNotFound(res) {
  sendJson(res, 404, { error: 'Not found' });
}

function handleMethodNotAllowed(res) {
  sendJson(res, 405, { error: 'Method not allowed' });
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;

  if (req.method === 'GET' && path === '/') {
    sendJson(res, 200, { message: 'Welcome to the JavaScript HTTP server' });
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
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const newItem = JSON.parse(body);
        if (!newItem.name) {
          sendJson(res, 400, { error: 'name is required' });
          return;
        }
        const id = `item-${Date.now()}`;
        const item = { id, name: newItem.name };
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

  handleNotFound(res);
});

server.listen(PORT, HOST, () => {
  console.log(`JavaScript HTTP server running at http://${HOST}:${PORT}/`);
});