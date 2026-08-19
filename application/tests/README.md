# Application tests

The backend has unit + API tests in `application/backend/test/` (run with
`npm test`). The integration scripts that run the full application through
real HTTP and a real database live in the repo-root `tests/` folder:

- `tests/application/integration.sh` — API flow test against any URL
  (local `http://localhost` or the deployed ALB).
- `tests/integration/e2e.sh` — end-to-end against the local Docker Compose
  stack.

```bash
# 1. start the local stack (from docker/)
docker compose up -d --build

# 2. run the API integration tests against it
bash tests/application/integration.sh http://localhost
```
