# ADR-001: Terraform for Infrastructure as Code

**Status:** Accepted
**Date:** 2026-08-12

## Context
We must provision a multi-tier AWS environment (VPC, ALB, EC2, RDS, ECR, WAF,
monitoring) that is reproducible, reviewable, and version-controlled.

## Options
1. **Terraform** — declarative HCL, huge AWS provider, module ecosystem, plan/apply workflow.
2. AWS **CloudFormation** — AWS-native, but verbose YAML/JSON and weaker module system.
3. **Manual console / scripts** — fastest to start, unrepeatable, no review.

## Decision
**Terraform** with reusable modules and a remote S3 backend + DynamoDB locking.

## Reason
`terraform plan` gives a reviewable diff before any change; state is stored
remotely and locked; modules make dev/prod reuse the same code; the community
ecosystem and learning curve are the best for this stack.

## Trade-offs
- State management requires care (solved: S3 + versioning + locking).
- HCL is another language to learn (acceptable).

## Consequences
- Every environment is reproducible from code.
- Infrastructure changes are peer-reviewed like code.
- Teams must follow the init → fmt → validate → plan → apply workflow.
