FROM rust:1.77-alpine AS builder

WORKDIR /app

COPY --chown=rust:rust Cargo.toml Cargo.lock ./
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,type=persistent,target=/app/target \
    cargo build --release

COPY --chown=rust:rust src ./src

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,type=persistent,target=/app/target \
    cargo build --release --bin rust-http-server

FROM alpine:3.20 AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/target/release/rust-http-server .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:3000/health || exit 1

CMD ["./rust-http-server"]