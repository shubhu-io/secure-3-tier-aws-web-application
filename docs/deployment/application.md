# Application Guide

## The application

A small but real three-tier app:

- **Frontend:** React (Vite) — login/register screen + an items CRUD list.
- **Backend:** Node.js/Express — JWT auth, items API, `/health` endpoint.
- **Database:** PostgreSQL — `users` and `items` tables.

```
Frontend (Nginx :80)
   │  /api, /health
   ▼
Backend (Node :3000)
   │
   ▼
PostgreSQL (:5432)
```

## Run locally (no AWS, free)

### Option A: Docker Compose (recommended)

```bash
cd docker
docker compose up --build
```

Wait for `frontend` to be healthy, then:

```bash
curl -s http://localhost/health
```

Expected:

```json
{"status":"ok","db":"connected","uptime":18,"timestamp":"2026-08-12T12:30:22.267Z"}
```

Open http://localhost in your browser: register an account, add an item.

Stop with:

```bash
docker compose down
```

### Option B: bare Node

1. Start PostgreSQL (Docker):

```bash
docker run -d --name pg \
  -e POSTGRES_DB=appdb -e POSTGRES_USER=app_user \
  -e POSTGRES_PASSWORD=local-dev-password -p 5432:5432 \
  postgres:16-alpine
```

2. Backend:

```bash
cd application/backend
cp .env.example .env        # then edit DB_PASSWORD/JWT_SECRET
npm install
npm run dev
```

3. Frontend:

```bash
cd application/frontend
npm install
npm run dev
```

Frontend dev server on http://localhost:5173, proxying `/api` to the backend.

## Configuration

All backend configuration is via environment variables (`.env.example`):

| Variable | Purpose |
| -------- | ------- |
| `PORT` | Backend port (3000) |
| `NODE_ENV` | `development` / `production` |
| `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD` | PostgreSQL connection |
| `JWT_SECRET` | Signs JWTs (required in production) |
| `JWT_EXPIRES_IN` | Token lifetime (8h) |

In production these are injected by the instance's user-data script from
**AWS Secrets Manager** — never committed, never in the image.

## API reference

| Method | Path | Auth | Body | Response |
| ------ | ---- | ---- | ---- | -------- |
| GET | `/health` | — | — | `{status, db, uptime, timestamp}` |
| GET | `/health/ready` | — | — | `200` ready / `503` db down |
| POST | `/api/auth/register` | — | `{email, password}` | `{token, user}` |
| POST | `/api/auth/login` | — | `{email, password}` | `{token, user}` |
| GET | `/api/items` | Bearer | — | `{items: []}` |
| POST | `/api/items` | Bearer | `{title, description?}` | `{item}` |
| DELETE | `/api/items/:id` | Bearer | — | `{deleted: id}` |

## Tests

```bash
cd application/backend && npm test     # unit + API tests (no DB needed)
cd application/frontend && npm run build
```

See [`docs/testing.md`](../testing.md) for the full strategy.

## Deploying

- **Automatically:** push to `main` → the CI/CD pipeline deploys to AWS.
- **Manually (local deploy):** `bash scripts/deploy.sh <tag> <region> <project> <env>`.
- **First deploy:** run the pipeline once so images exist in ECR and the SSM
  parameters point at them; then the ASG's instances become healthy.
