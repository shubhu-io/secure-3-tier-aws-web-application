# ADR-002: Private Database Subnets

**Status:** Accepted
**Date:** 2026-08-12

## Context
The database holds sensitive user data. A public database is one of the most
common causes of real-world data breaches.

## Options
1. **Private DB subnets** — no public IP, no internet route.
2. Public subnets with security-group-only protection.
3. Database outside the VPC entirely.

## Decision
RDS lives in **dedicated private DB subnets** with no default route and a
security group that only accepts traffic from the app security group.

## Reason
Defense in depth: routing (no route = no path), NACL (stateless subnet
firewall), and SG (stateful app-only firewall) must **all** fail before the
database is exposed. Publicly accessible RDS was rejected outright.

## Trade-offs
- App instances need to be in a VPC that can route to RDS (they are).
- DB access for operations is via the app tier / SSM, not direct.

## Consequences
- The database is unreachable from the internet even if credentials leak.
- Auditors can verify `PubliclyAccessible = false`.
- `tests/security/security-tests.sh` asserts this automatically.
