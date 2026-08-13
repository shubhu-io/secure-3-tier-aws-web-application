# ADR-004: Auto Scaling Group for Compute

**Status:** Accepted
**Date:** 2026-08-12

## Context
Production instances die. Without automation, an outage lasts until a human
intervenes — and load varies, so fixed capacity is wasteful.

## Options
1. **ASG** with a Launch Template — self-healing + scale out/in via policy.
2. Fixed EC2 instances with manual replacement.
3. Managed orchestration (ECS/EKS) — more moving parts for this project.

## Decision
**Auto Scaling Group** with an encrypted launch template, ELB health checks,
and a target-tracking CPU policy (70%).

## Reason
The ASG replaces unhealthy instances automatically, keeps capacity across two
AZs, and scales with load — three production properties for the price of
declarative config. ECS/EKS were deferred (see ADR-005) to keep the compute
model approachable.

## Trade-offs
- The ASG needs a launch template and health-check wiring (done).
- Rolling deploys use instance refresh rather than in-place blue/green.

## Consequences
- Killing an instance triggers replacement in minutes (see failure runbook).
- CPU load scales instances between `min_size` and `max_size`.
- New instances always boot from the current launch template.
