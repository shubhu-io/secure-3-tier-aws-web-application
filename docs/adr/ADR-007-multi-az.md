# ADR-007: Multi-AZ Everything

**Status:** Accepted (production); dev uses single-AZ-leaning but still 2 AZs
**Date:** 2026-08-12

## Context
An Availability Zone (physical data center failure domain) can fail. If all
our resources sit in one AZ, that failure is an outage.

## Options
1. **Multi-AZ** — spread compute, ALB, and DB across ≥ 2 AZs.
2. Single-AZ — cheaper, but a single failure domain.

## Decision
- **Always:** app subnets + ALB across **two AZs**; ASG can place instances in both.
- **Dev:** single NAT Gateway (cost), RDS single-AZ.
- **Prod:** two NAT Gateways, **RDS Multi-AZ**, `deletion_protection = true`.

## Reason
The app tier is the cheap place to be resilient — ASG across 2 AZs means an AZ
loss still serves traffic. RDS Multi-AZ costs ~2× the instance but is the
difference between a 2-minute failover and hours of restore in production.

## Trade-offs
- Multi-AZ RDS doubles DB cost (justified in prod, not in dev).
- A second NAT Gateway adds ~$32/month (justified in prod).

## Consequences
- Single instance loss → ASG replacement, no outage.
- Single AZ loss → the other AZ keeps serving; prod DB fails over.
- Cost guide (`docs/cost-guide.md`) documents the dev vs prod trade-off.
