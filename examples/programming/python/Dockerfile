FROM python:3.13-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

FROM python:3.13-slim AS runtime

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/app.py .
COPY --from=builder /app/requirements.txt .

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:3000/health || exit 1

CMD ["python", "app.py"]