# ============================================================================
# Database image for the LOCAL dev stack (NO AWS required).
#
# Official mysql base plus the application schema (init.sql), which is
# executed automatically the first time a fresh data volume is created.
# The application also applies the same schema idempotently at startup
# (application/backend/src/initDb.js), so this copy is a convenience that
# lets you inspect/use the DB before the backend first runs.
#
# Build context: repository root
#   docker build -f docker/database/Dockerfile .
# ============================================================================

FROM mysql:8.0

# docker-entrypoint-initdb.d/*.sql runs once on first init of an empty data dir
COPY application/database/init.sql /docker-entrypoint-initdb.d/01-init.sql
