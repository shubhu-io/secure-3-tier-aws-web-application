# ADR-008: Managed Kubernetes (Amazon EKS)

**Status:** Accepted
**Date:** 2026-08-18

## Context

The application deploys to EC2 + Docker Compose via SSM deploy pointers and an
ASG instance refresh. That works, but managing containers on VMs has limits:
no native rollout controls, no declarative desired state, and no pod-level
scheduling. The team wants a **modern container-orchestration path** that
coexists with (and can eventually replace) the EC2 path.

## Options

1. **Amazon EKS** — managed Kubernetes control plane; worker nodes run in the
   existing private app subnets; integrates with ECR, IAM, and the current
   Terraform codebase.
2. **k3s on the existing EC2 instances** — lightweight, cheaper, but the
   instances are already provisioned by the ASG for Docker Compose; the control
   plane would not be managed and HA is DIY.
3. **ECS / ECS Fargate** — AWS-native but not "real" Kubernetes; doesn't
   satisfy the learning goal of running Kubernetes and would be a different
   orchestrator entirely.
4. **No orchestrator** — stay on EC2 + Compose; accepted today but doesn't
   scale past a handful of instances.

## Decision

**Amazon EKS**, provisioned by a new Terraform `eks` module, gated behind
`enable_eks` (opt-in for cost). The EC2 + Docker Compose path stays and the two
coexist.

## Reason

- **Managed control plane** — AWS handles the API server, etcd, upgrades, and
  patching, matching the project's "managed where it matters" philosophy (like
  RDS).
- **Reuses the existing VPC** — the node group lands in the private app
  subnets, so NAT, flow logs, and the RDS security model stay intact; the EKS
  cluster security group is added as a source to the DB security group.
- **Standard manifests** — the app deploys from `kubernetes/` with the same
  ECR images, keeping the "one image, many runtimes" story.
- **Same security posture** — private nodes, no secrets in Git (credentials are
  materialized into a Kubernetes Secret from Secrets Manager at deploy time),
  least-privilege IAM, immutable git-SHA image tags.

## Trade-offs

- Cost: control plane + node group is the most expensive add-on (~$100–150/mo).
- Operational surface: Kubernetes concepts (pods, services, HPA, PDB) add
  learning and operational overhead.
- Public API endpoint is enabled for CI `kubectl`; should be locked down
  (CIDR allow-list or VPN) before production.

## Consequences

- New `terraform/modules/eks` (cluster, node group, IAM, access entries) and
  the `kubernetes/` manifest folder.
- Pipelines gain an optional EKS deploy stage (`deploy-eks.sh`) behind
  `DEPLOY_EKS`.
- Rollback is now also `kubectl rollout undo`, alongside re-pointing the SSM
  parameter.
- Future upgrades documented: AWS Load Balancer Controller + WAF, IRSA /
  External Secrets Operator, Karpenter / Cluster Autoscaler.
