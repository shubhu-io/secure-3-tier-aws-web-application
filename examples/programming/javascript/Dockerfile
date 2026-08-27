FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY src ./src
COPY test ./test

FROM node:22-alpine AS runtime

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/package.json ./
COPY --from=builder /app/src ./src
COPY --from=builder /app/test ./test
COPY --from=builder /app/node_modules ./node_modules

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:3000/health || exit 1

CMD ["node", "src/index.js"]