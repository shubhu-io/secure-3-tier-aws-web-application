# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-08-12

### Added

- Full n-tier architecture: VPC (public/app/DB subnets), NAT, IGW, Flow Logs.
- Layered security groups (ALB → App → DB) plus Network ACLs for each tier.
- ALB with HTTPS listener (ACM) and HTTP→HTTPS redirect.
- AWS WAF association with managed rule sets.
- EC2 Launch Template + Auto Scaling Group with target-tracking scaling.
- RDS PostgreSQL in private DB subnets, encrypted, multi-AZ option,
  credentials managed by AWS Secrets Manager.
- ECR repositories for frontend and backend with lifecycle + scan policies.
- React (Vite) frontend and Express/PostgreSQL backend with auth and health
  endpoints.
- Production Dockerfiles (multi-stage, non-root, health checks) + Compose for
  local development.
- GitHub Actions CI/CD: tests, builds, Trivy scan, ECR push, SSM parameter
  update, ASG instance refresh, smoke test.
- CloudWatch alarms (CPU, ALB 5xx, unhealthy hosts, RDS) → SNS.
- CloudTrail and VPC Flow Logs.
- Comprehensive docs: architecture, deployment, operations, runbooks, ADRs,
  troubleshooting, DR, cost guide, interview questions, testing guide.
- Mermaid diagrams for architecture, network, security, CI/CD, request flow,
  deployment flow, failure flow, and disaster recovery.

[Unreleased]: https://github.com/your-org/secure-ntier-cloud-platform
