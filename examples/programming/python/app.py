import json
import os
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, List

items: List[Dict[str, str]] = []


class RequestHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code: int, data: dict) -> None:
        body = json.dumps(data).encode('utf-8')
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        path = urllib.parse.urlparse(self.path).path

        if path == '/':
            self._send_json(200, {'message': 'Welcome to the Python HTTP server'})
        elif path == '/health':
            self._send_json(200, {'status': 'healthy'})
        elif path == '/items':
            self._send_json(200, {'items': items})
        else:
            self._send_json(404, {'error': 'Not found'})

    def do_POST(self) -> None:
        path = urllib.parse.urlparse(self.path).path

        if path == '/items':
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')

            try:
                data = json.loads(body) if body else {}
            except json.JSONDecodeError:
                self._send_json(400, {'error': 'Invalid JSON'})
                return

            if not isinstance(data, dict) or 'name' not in data:
                self._send_json(400, {'error': 'name is required'})
                return

            item = {'id': f'item-{len(items) + 1}', 'name': data['name']}
            items.append(item)
            self._send_json(201, item)
        else:
            self._send_json(404, {'error': 'Not found'})

    def do_DELETE(self) -> None:
        path = urllib.parse.urlparse(self.path).path

        if path == '/items':
            items.clear()
            self._send_json(200, {'removed': True})
        else:
            self._send_json(404, {'error': 'Not found'})

    def log_message(self, format: str, *args) -> None:
        pass


def main() -> None:
    PORT = int(os.environ.get('PORT', '3000'))
    HOST = os.environ.get('HOST', '0.0.0.0')
    server = HTTPServer((HOST, PORT), RequestHandler)
    print(f'Python HTTP server running at http://{HOST}:{PORT}/')
    server.serve_forever()


if __name__ == '__main__':
    main()