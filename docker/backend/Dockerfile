# ============================================================================
# Backend Dockerfile - production image
# Build context: repository root
#   docker build -f docker/backend/Dockerfile .
#
# Multi-stage: dependencies -> minimal runtime as non-root user.
# ============================================================================

FROM node:22-alpine AS build

WORKDIR /app
COPY application/backend/package.json application/backend/package-lock.json* ./
RUN npm ci --omit=dev
COPY application/backend/src ./src

# --- runtime ---
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# Non-root user (least privilege)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Remove package managers not needed at runtime (reduces attack surface
# and removes npm-bundled dependencies with known vulnerabilities).
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack

COPY --from=build --chown=appuser:appgroup /app /app

USER appuser

EXPOSE 3000

# Healthcheck so orchestrators / compose know the container is alive
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || '3000') + '/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "src/server.js"]
