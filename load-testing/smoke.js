import http from 'k6/http';
import { check, sleep } from 'k6';

// Smoke test: prove the deployed stack serves traffic end-to-end.
// Run:  BASE_URL=https://<alb-dns> k6 run load-testing/smoke.js
const BASE_URL = __ENV.BASE_URL || 'http://localhost';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    checks: ['rate>0.99'],
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const health = http.get(`${BASE_URL}/health`);
  check(health, {
    'health is 200': (r) => r.status === 200,
    'db connected': (r) => r.json('db') === 'connected',
  });

  const items = http.get(`${BASE_URL}/api/items`);
  check(items, {
    'items is 200': (r) => r.status === 200,
  });

  sleep(1);
}
