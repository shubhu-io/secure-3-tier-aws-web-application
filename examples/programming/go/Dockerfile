FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .

RUN go build -o server .

FROM alpine:3.20 AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/server .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:8080/health || exit 1

CMD ["./server"]