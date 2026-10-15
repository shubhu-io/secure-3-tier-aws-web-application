# Docker — Local & Production Container Stack

Container packaging for the secure-ntier platform. Everything here works with a
plain **Docker Desktop / Docker Engine** — no AWS, Azure or GCP required — which
makes the stack ideal for fast local development and for reproducing the exact
runtime images that later get pushed to ECR / ACR / Artifact Registry.

```
docker/
├── docker-compose.yml        # local dev stack (builds from source, no cloud)
├── docker-compose.prod.yml   # prod reference (pulls prebuilt images)
├── .env.example              # copy to .env to override ports/secrets
├── README.md                 # this file
├── backend/
│   └── Dockerfile            # multi-stage, non-root Node.js 22 image
├── frontend/
│   └── Dockerfile            # Vite build -> static Nginx serve + API proxy
├── nginx/
│   └── nginx.conf            # SPA serving, /api + /health proxy to backend
├── database/
│   ├── Dockerfile            # mysql:16-alpine + init.sql schema
│   └── README.md             # how DB initialisation works
└── scripts/                  # friendly wrappers around the common commands
    ├── common.sh             # shared env loading + helpers
    ├── up.sh                 # build, start, wait for health
    ├── down.sh               # stop and remove containers
    ├── reset.sh              # wipe the DB volume and start fresh
    ├── status.sh             # container status + ports
    ├── logs.sh               # follow logs
    ├── seed.sh               # seed sample data
    ├── test.sh               # run the local validation suite
    └── scan.sh               # Trivy scan of the built images
```

## Quick start (local)

```bash
cp docker/.env.example docker/.env    # optional - everything has safe defaults
bash docker/scripts/up.sh             # build + start + wait for health
```

| Service   | URL                                |
| --------- | ---------------------------------- |
| Frontend  | http://localhost                   |
| Backend   | http://localhost:3000/health       |
| mysql  | localhost:3306 (`app_user`/`appdb`)|

Use `--seed` to fill the app with sample data once it is healthy:

```bash
bash docker/scripts/up.sh --seed
```

## Services

| Service    | Image                                              | Exposes | Notes                                    |
| ---------- | -------------------------------------------------- | ------- | ---------------------------------------- |
| `db`       | `docker/database/Dockerfile` (mysql:16-alpine)  | 3306    | schema auto-applied on first volume init |
| `backend`  | `docker/backend/Dockerfile` (node:22-alpine)       | 3000    | runs as non-root, `restart: unless-stopped`, healthcheck |
| `frontend` | `docker/frontend/Dockerfile` (nginx:1.29-alpine)   | 80      | serves the SPA + proxies `/api` → backend |

Dependencies: `backend` starts only after `db` is healthy (mysql ready);
`frontend` starts after `backend`. Compose declares the volume `pgdata` for the
database, so data survives restarts — `bash docker/scripts/reset.sh` wipes it.

## Environment & secrets

Nothing sensitive is hardcoded. Read `docker/.env.example`, copy it to
`docker/.env`, and tweak:

```bash
JWT_SECRET=…              # change this for anything beyond a single laptop
DB_NAME / DB_USER / DB_PASSWORD   # set in pairs (db + backend read the same)
DB_PORT_MAP / BACKEND_PORT_MAP / FRONTEND_PORT_MAP   # host ports
```

`docker/.env` is gitignored. Compose uses it for `${VAR}` interpolation and
every value falls back to a safe local-development default, so the stack also
runs with **no `.env` at all**. In production, secrets are injected from the
SSM SecureString parameter by the instance `user-data` scripts — never from a file
(see `terraform/cloud/aws/modules/compute/user-data.sh`).

## Commands cheat-sheet

| Task                 | Command                                  |
| -------------------- | ---------------------------------------- |
| Start + wait health  | `bash docker/scripts/up.sh`              |
| Follow logs          | `bash docker/scripts/logs.sh`            |
| Status               | `bash docker/scripts/status.sh`          |
| Stop                 | `bash docker/scripts/down.sh`            |
| Wipe DB + restart    | `bash docker/scripts/reset.sh`           |
| Seed sample data     | `bash docker/scripts/seed.sh`            |
| Run validation suite | `bash docker/scripts/test.sh`            |
| Trivy scan images    | `bash docker/scripts/scan.sh`            |
| psql into the DB     | `docker compose -f docker/docker-compose.yml exec db psql -U app_user -d appdb` |

Equivalent root-level entry points also exist: `make local-up`, `make
local-down`, `make local-status`, `make local-seed`, `make local-test` and
`bash scripts/local-up.sh --logs`.

## Production compose

`docker/docker-compose.prod.yml` is the human-readable version of the compose
stack that EC2/VMSS instances bootstrap at first boot. It differs from the
local stack in three meaningful ways:

1. **Pulls prebuilt images** (`BACKEND_IMAGE` / `FRONTEND_IMAGE`) instead of
   building from source.
2. **No database service** — the DB is managed (RDS / DBaaS) and reached via
   `DB_HOST`.
3. **Fails fast on missing secrets** — `DB_HOST`, `DB_*` and `JWT_SECRET` must
   be provided or the stack refuses to start (`${VAR:?}`).

```bash
cp docker/.env.example docker/.env   # set BACKEND_IMAGE/FRONTEND_IMAGE + DB_HOST
docker compose --env-file docker/.env -f docker/docker-compose.prod.yml up -d
```

Only the frontend is exposed to the host (`80:80`); the backend lives on an
internal-only bridge network. Each service runs with a healthcheck and bounded
`json-file` logging.

## Building images manually

Both local Dockerfiles use the repository root as their build context:

```bash
docker build -t secure-ntier-backend:latest -f docker/backend/Dockerfile .
docker build -t secure-ntier-frontend:latest -f docker/frontend/Dockerfile .
docker build -t secure-ntier-db:latest    -f docker/database/Dockerfile .
```

Push them to your registry when you are ready to deploy (see
`cicd/scripts/stack-push.sh` for the automated path).

## Security notes

- Backend runs as a **non-root** user; `npm`/`corepack` are removed from the
  runtime image.
- All base images are patched on build (`apk upgrade --no-cache`) so known
  CRITICAL/HIGH CVEs are not shipped.
- Frontend nginx config enables gzip + long cache headers and proxies only the
  expected routes (`/api`, `/health`, `/health/ready`).
- The local DB uses a password from `.env` (dev-only); production credentials
  come from the SSM SecureString parameter.
- Images are scanned with **Trivy** (CRITICAL/HIGH fail) in CI
  (`.github/workflows/ci.yml`) and locally via `docker/scripts/scan.sh`.
