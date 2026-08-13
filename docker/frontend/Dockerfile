# ============================================================================
# Frontend Dockerfile - production image
# Build context: repository root
#   docker build -f docker/frontend/Dockerfile .
#
# Stage 1: build the React app with Vite
# Stage 2: serve static files with Nginx and proxy /api to the backend
# ============================================================================

FROM node:20-alpine AS build

WORKDIR /app
COPY application/frontend/package.json application/frontend/package-lock.json* ./
RUN npm ci
COPY application/frontend/ ./
RUN npm run build

# --- runtime: Nginx ---
FROM nginx:1.27-alpine

# Nginx config: serves the SPA and proxies /api + /health to backend:3000
COPY docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx runs as a non-root user by default in the official image

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O - http://127.0.0.1/health >/dev/null 2>&1 || exit 1
