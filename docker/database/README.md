# Docker / database

The `db` service in `docker/docker-compose.yml` builds this folder's
`Dockerfile` instead of pulling a stock `postgres` image, so the application
schema is already in place when Postgres first initializes a fresh volume.

## How initialisation works

1. The image copies `application/database/init.sql` to
   `/docker-entrypoint-initdb.d/01-init.sql`.
2. On the **first** start with an empty data volume, the official Postgres
   entrypoint runs every `*.sql`/`*.sh` file in that directory before the
   server accepts connections.
3. The schema is idempotent (`CREATE TABLE IF NOT EXISTS`), so it is safe for
   repeated runs.
4. As a safety net the backend also applies the same schema at startup
   (`application/backend/src/initDb.js`), so nothing is required from this
   image for normal app operation.

> Note: scripts in `/docker-entrypoint-initdb.d/` run only when the data
> volume is created. Existing volumes are left untouched, so if you change
> `init.sql` you must reset the volume to see the change:
>
> ```bash
> bash docker/scripts/reset.sh        # docker compose down -v + up
> ```

## Credentials

The postgres container uses `POSTGRES_DB`, `POSTGRES_USER` and
`POSTGRES_PASSWORD`. These map 1:1 to `DB_*` variables read by the backend,
and both come from the same `docker/.env` (see `docker/.env.example`), so they
can never drift apart.

Defaults for the local stack only:

| Variable       | Default                     |
| -------------- | --------------------------- |
| `DB_NAME`      | `appdb`                     |
| `DB_USER`      | `app_user`                  |
| `DB_PASSWORD`  | `local-dev-password`        |
| `DB_PORT_MAP`  | `5432`                      |

## Inspecting the database

```bash
docker compose -f docker/docker-compose.yml exec db \
  psql -U app_user -d appdb
```