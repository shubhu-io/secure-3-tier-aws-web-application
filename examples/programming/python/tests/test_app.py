import json
import threading
import time
import urllib.request
import urllib.parse
import pytest

from app import RequestHandler, items


@pytest.fixture(autouse=True)
def clear_items():
    items.clear()
    yield
    items.clear()


@pytest.fixture(autouse=True)
def start_server():
    import os
    import http.server

    port = 3001
    server = http.server.HTTPServer(('127.0.0.1', port), RequestHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.1)  # Give server time to start
    yield server
    server.shutdown()


class TestPythonHTTPServer:
    def _make_request(self, method: str, path: str, body: dict = None) -> dict:
        url = f'http://127.0.0.1:3001{path}'
        headers = {'Content-Type': 'application/json'} if body else {}
        data = json.dumps(body).encode('utf-8') if body else None

        req = urllib.request.Request(url, data=data, headers=headers, method=method if method else 'GET')
        try:
            with urllib.request.urlopen(req) as resp:
                return {'status': resp.status, 'data': json.loads(resp.read().decode())}
        except urllib.error.HTTPError as e:
            return {'status': e.code, 'data': json.loads(e.read().decode())}

    def test_get_welcome(self) -> None:
        status_data = self._make_request('GET', '/')
        assert status_data['status'] == 200
        assert status_data['data']['message'] == 'Welcome to the Python HTTP server'

    def test_get_health(self) -> None:
        status_data = self._make_request('GET', '/health')
        assert status_data['status'] == 200
        assert status_data['data']['status'] == 'healthy'

    def test_get_items_empty(self) -> None:
        status_data = self._make_request('GET', '/items')
        assert status_data['status'] == 200
        assert status_data['data']['items'] == []

    def test_post_item_valid(self) -> None:
        status_data = self._make_request('POST', '/items', {'name': 'widget'})
        assert status_data['status'] == 201
        assert status_data['data']['name'] == 'widget'

    def test_post_item_missing_name(self) -> None:
        status_data = self._make_request('POST', '/items', {})
        assert status_data['status'] == 400
        assert status_data['data']['error'] == 'name is required'

    def test_delete_items(self) -> None:
        self._make_request('POST', '/items', {'name': 'widget'})
        status_data = self._make_request('DELETE', '/items')
        assert status_data['status'] == 200
        assert status_data['data']['removed'] is True

    def test_get_items_after_create(self) -> None:
        self._make_request('POST', '/items', {'name': 'widget'})
        status_data = self._make_request('GET', '/items')
        assert status_data['status'] == 200
        assert len(status_data['data']['items']) == 1
        assert status_data['data']['items'][0]['name'] == 'widget'