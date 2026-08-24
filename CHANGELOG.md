# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `stack.json` manifest — the single source of truth for services (name, port,
  public, source_dir, dockerfile, toolchain, ci_steps, health_path), the
  database engine/version/port, and runtimes. A new service needs only one
  `stack.json` entry.
- Manifest-driven CI/CD scripts: `cicd/scripts/stack-validate.sh`,
  `stack-info.sh`, `stack-ci.sh`, `stack-push.sh` (shared by GitHub Actions and
  Jenkins).
- `cicd/Jenkinsfile-ci` — Jenkins CI pipeline mirroring `ci.yml`.
- Self-hosted Jenkins: new `terraform/modules/jenkins/` module (optional
  `enable_jenkins` flag) + `docs/deployment/jenkins.md` guide.
- Kubernetes rendering: `kubernetes/scripts/render-manifests.sh` generates
  per-service Deployment/Service/HPA/PDB from `stack.json`; static
  deployment/service/hpa/pdb YAML removed in favor of the manifest.
- EKS deployment path: `terraform/modules/eks/`, `kubernetes/` manifests,
  `cicd/scripts/deploy-eks.sh`, `docs/deployment/eks.md`, ADR-008.
- Architecture Decision Record [ADR-008](docs/adr/ADR-008-eks.md) for Amazon EKS.
- `tests/infrastructure/stack-validate.sh` — cluster-free test of the manifest
  scripts: `stack-validate.sh` accepts the repo `stack.json` (and rejects
  malformed manifests), every `stack-info.sh` subcommand returns the expected
  value, and `render-manifests.sh` produces the right shapes (2 services ×
  Deployment/Service/HPA/PDB, one LoadBalancer, `fsGroup` on the internal
  service only). Needs `jq` on PATH (skips if missing).

### Changed

- Cross-platform fixes for the manifest scripts: `stack-info.sh` and
  `stack-validate.sh` strip `\r` from `jq` output (Windows Git Bash/WSL
  compatibility), and `stack-ci.sh` scopes `MSYS2_ARG_CONV_EXCL` to `docker` so
  container-side `/workspace` paths survive on Git Bash while `jq` still gets
  the Windows-converted host path. Trivy-in-docker is skipped with a warning on
  Windows hosts (no Linux docker socket).
- `scripts/deploy.sh` now builds/pushes every service in one `stack-push.sh`
  call instead of per-service `build-and-push.sh` lines.

- Kubernetes deploy flow: `kubectl apply -k` (namespace + configmap) followed by
  `kubectl apply -f -` of rendered manifests (see `kubernetes/scripts/deploy.sh`).
- `kubernetes/configmap.yaml` trimmed to non-secret app config only
  (`NODE_ENV`, `DB_POOL_MAX`, `JWT_EXPIRES_IN`); `PORT`/`DB_PORT` come from
  `stack.json` and DB credentials from the `app-db-secret` Secret.
- CI/CD pipeline is manifest-driven: each service runs its `ci_steps` in its
  toolchain container, is scanned with Trivy, and pushed to ECR individually.
- Docs updated across `docs/architecture/*`, `docs/deployment/*`,
  `docs/phases.md`, `docs/cost-guide.md`, README, and diagrams for the
  manifest-driven design (small → production).

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

[Unreleased]: https://github.com/shubhu-io/secure-ntier-cloud-platform
