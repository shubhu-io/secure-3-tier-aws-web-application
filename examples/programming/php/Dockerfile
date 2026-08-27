FROM php:8.3-fpm-alpine AS builder

WORKDIR /app

RUN apk add --no-cache $phpExtensions sqlite-dev

COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader

COPY src ./src

FROM php:8.3-fpm-alpine AS runtime

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/vendor ./vendor
COPY --from=builder /app/src ./src

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:3000/health || exit 1

CMD ["php", "-S", "0.0.0.0:3000", "-t", "src"]