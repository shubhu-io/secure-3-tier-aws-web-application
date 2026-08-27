import http from 'k6/http';
import { check, group } from 'k6';

// Load / stress test sized to exercise ASG scale-out (CPU > 70% alarm).
// Mirrors the "Load spike" failure test in the README and docs/runbooks.
// Start small; only raise stages on a disposable environment.
//
//   BASE_URL=https://<alb-dns> k6 run load-testing/stress.js
const BASE_URL = __ENV.BASE_URL || 'http://localhost';

export const options = {
  scenarios: {
    ramp: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      stages: [
        { target: 50, duration: '2m' },
        { target: 200, duration: '5m' },
        { target: 400, duration: '3m' },
        { target: 0, duration: '1m' },
      ],
    },
  },
  thresholds: {
    checks: ['rate>0.95'],
    http_req_duration: ['p(95)<1500'],
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  group('read path', () => {
    const res = http.get(`${BASE_URL}/api/items`);
    check(res, { 'status 200': (r) => r.status === 200 });
  });
}
