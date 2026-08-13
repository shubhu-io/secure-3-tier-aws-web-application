# ADR-006: Managed Amazon RDS (PostgreSQL)

**Status:** Accepted
**Date:** 2026-08-12

## Context
We need a reliable PostgreSQL that the app depends on for auth and data.

## Options
1. **Amazon RDS PostgreSQL** — managed backups, patching, HA, encryption.
2. Self-managed PostgreSQL on EC2 — full control, you own every failure.
3. A DB-as-a-service outside AWS — adds a provider and network hop.

## Decision
**Amazon RDS PostgreSQL** in private subnets.

## Reason
RDS provides, out of the box: automated backups + point-in-time restore,
storage encryption, Multi-AZ failover (prod), storage auto-scaling, and
managed patching. Self-managing a database is a full-time job we don't need —
the app just needs a reliable Postgres.

## Trade-offs
- Costs more than running your own Postgres on a small EC2 (still modest).
- Some knobs (e.g. `search_path` changes) are AWS-managed.

## Consequences
- `backup_retention_days` gives an RPO of ~5 minutes in production.
- Multi-AZ gives an RTO of ~1-2 minutes for DB failures.
- Credentials are auto-generated and live in Secrets Manager.
