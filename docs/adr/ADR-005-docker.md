# ADR-005: Docker on EC2 (vs ECS / EKS)

**Status:** Accepted
**Date:** 2026-08-12

## Context
We must ship and run the frontend + backend consistently across local dev and
AWS, and make deploys reproducible.

## Options
1. **Docker on EC2 (compose)** — full control, teaches the Docker mental model, no orchestrator complexity.
2. **ECS/Fargate** — managed, but adds task definitions/services/roles complexity and hides Docker.
3. **EKS** — powerful but operationally heavy for this scope.

## Decision
**Docker containers on EC2**, composed with `docker compose`, images stored in
**ECR**, launched by user-data at boot.

## Reason
Keeps the "one image = one app" guarantee (the image tested in CI is the one
deployed), works identically locally and in production, and keeps the learning
path simple. The ASG already handles instance replacement; compose handles
multi-container wiring on the host.

## Trade-offs
- No native orchestrator scheduling (acceptable for 2 containers).
- Each instance runs its own containers (state duplication is fine — app is stateless).

## Consequences
- Deploys = new image SHA in SSM + instance refresh.
- The local `docker-compose.yml` reproduces the production container topology.
- Path to Fargate/EKS later is mostly a packaging exercise.
