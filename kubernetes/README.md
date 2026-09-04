# Kubernetes deployment

This folder deploys the same **React + Node + PostgreSQL** application on a
Kubernetes cluster - the modern alternative to the EC2 + Docker Compose path.
It works with **Amazon EKS** (provisioned by the Terraform `eks` module) or any
local cluster (kind / minikube / k3d).

The Kubernetes path is **stack.json-driven**, exactly like the EC2 path: the
per-service Deployment / Service / HPA / PDB manifests are **rendered from
`stack.json`** at deploy time, so a new service only needs a `stack.json`
entry - never a manifest edit.

## Layout

| File | What it is |
| ---- | ---------- |
| `namespace.yaml` | Everything runs in the `secure-ntier` namespace |
| `configmap.yaml` | Non-secret app config shared by every service |
| `secret.yaml.example` | Template of the `app-db-secret` **- never apply as-is** |
| `kustomization.yaml` | Applies the static support resources (namespace + config) |
| `scripts/render-manifests.sh` | **Renders** Deployment/Service/HPA/PDB for every service from `stack.json` |
| `scripts/deploy.sh` | Connect + materialise secrets + apply (static + rendered) + roll + verify |
| `scripts/undeploy.sh` | Remove the `secure-ntier` namespace |

Per-service manifests are **not** committed any more - they come from
`render-manifests.sh`, which mirrors the old hand-written ones:

- Deployment: rolling update, non-root security context, resource requests,
  readiness probe on `<health_path>` and liveness probe on `<health_path>`
  (internal) or `/` (public - nginx must not restart when the backend is down).
- Service: the **one `public` service** becomes a `LoadBalancer` (AWS NLB,
  internet-facing, `:80 -> :<port>`); everything else is `ClusterIP`.
- `HorizontalPodAutoscaler` per service (CPU 70%, like the EC2 policy).
- `PodDisruptionBudget` per service (never below 1 pod during maintenance).

## How secrets work

Credentials never live in Git. `scripts/deploy.sh` (in AWS mode) reads the DB
credentials + JWT secret from **AWS Secrets Manager** and materialises them into
a Kubernetes Secret named `app-db-secret`, which every Deployment loads via
`secretRef`. The backend then behaves exactly like the EC2 path.

## Deploying to EKS

Prerequisites: the Terraform EKS module applied (`enable_eks = true`), `kubectl`
installed, AWS credentials configured, and the CI/CD IAM principal granted
cluster access (see `docs/deployment/eks.md`).

```bash
bash kubernetes/scripts/deploy.sh <git-sha> ap-south-1 dev secure-ntier
```

This:
1. Writes the kubeconfig with `aws eks update-kubeconfig`
2. Reads the DB secret from Secrets Manager and creates `app-db-secret`
3. Applies the static support (namespace + config) and **renders + applies** the
   per-service manifests from `stack.json`
4. Points the deployments at the ECR images for `<git-sha>` (one per service)
5. Waits for the rolling updates, then prints the NLB endpoint

Verify:

```bash
curl -s http://<NLB_ENDPOINT>/health
```

## Local cluster (no AWS)

```bash
# 1. create the cluster + the secret yourself (see secret.yaml.example)
kubectl create ns secure-ntier
kubectl -n secure-ntier create secret generic app-db-secret \
  --from-literal=DB_HOST=localhost --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=appdb --from-literal=DB_USER=app_user \
  --from-literal=DB_PASSWORD=local-dev-password \
  --from-literal=JWT_SECRET=local-dev-secret-change-me-1234567890

# 2. deploy without touching AWS
AWS_CREDS_MODE=local bash kubernetes/scripts/deploy.sh <tag> ap-south-1 dev secure-ntier

# 3. port-forward to reach the public service locally
kubectl -n secure-ntier port-forward svc/frontend 8080:80
curl -s http://localhost:8080/health
```

## Validating the manifests (no cluster needed)

```bash
bash tests/infrastructure/kubernetes-validate.sh
```

Runs `kustomize build` on the static files, renders the per-service manifests
from `stack.json`, and (when a cluster is reachable) dry-runs them all.

## Production upgrades

- **HTTPS + AWS WAF**: install the [AWS Load Balancer
  Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
  (IRSA + Helm), then create an `Ingress` with TLS + an associated WAF web ACL
  instead of the plain `LoadBalancer` service.
- **External secrets**: replace the pipeline-materialised secret with
  [External Secrets Operator](https://external-secrets.io) or the AWS Secrets
  Store CSI driver so secrets never pass through CI.
- **Cluster autoscaling**: add the Cluster Autoscaler / Karpenter so nodes
  scale with the HPA.