# ADR-003: Application Load Balancer

**Status:** Accepted
**Date:** 2026-08-12

## Context
We need one entry point that distributes traffic across multiple app
instances, terminates TLS, and health-checks targets.

## Options
1. **ALB** — L7 routing, path/host rules, TLS termination, native target-group health checks, integrates with ASG.
2. NLB — L4, fast, but no HTTP routing/health semantics.
3. Single EC2 + reverse proxy — no HA, single point of failure.

## Decision
**Application Load Balancer** in the public subnets.

## Reason
The app is HTTP-based; the ALB gives us HTTPS termination with ACM, health
checks, and automatic integration with the Auto Scaling Group (instances
register/unregister themselves). L7 features (WAF association, path rules)
are free for future use.

## Trade-offs
- ALB has a fixed monthly cost (~$16/month) — acceptable for HA.
- L7 inspection is slightly slower than NLB L4 — irrelevant for this app.

## Consequences
- Traffic flow: WAF → ALB :443 → target group :80.
- HTTP → HTTPS redirect is handled at the listener (no app code needed).
