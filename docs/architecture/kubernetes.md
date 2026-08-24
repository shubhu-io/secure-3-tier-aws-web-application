# Kubernetes architecture (EKS)

The **modern deployment path**. The same images that run on VM + Docker
Compose also run on a managed Kubernetes cluster - Amazon EKS - provisioned by
the Terraform `eks` module (`terraform/cloud/aws/modules/eks/`; AKS and GKE
ports live under `terraform/cloud/azure/modules/aks/` and
`terraform/cloud/gcp/modules/gke/`). Both paths coexist; pick one (or both)
per environment.

> **Cloud mapping** — the cluster story is the same shape everywhere, but the
> AWS/EKS content below is the reference implementation; the Azure and GCP
> modules are ports pending live validation.
>
> | Concern | AWS | Azure | GCP |
> | ------- | --- | ----- | --- |
> | Managed cluster | EKS | AKS | GKE |
> | Node group | EC2 managed node group | node pool | node pool |
> | Public edge Service | NLB via `type: LoadBalancer` | Azure LB / Application Gateway ingress | Google Cloud Load Balancer |
> | Secrets materialization | Secrets Manager → K8s Secret | Key Vault → K8s Secret | Secret Manager → K8s Secret |
> | Cluster access for CI | access entry + IAM | `az aks get-credentials` + RBAC | `gcloud container clusters get-credentials` + IAM |
>
> The normalized Terraform outputs (`kubeconfig_command`,
> `cluster_endpoint`) return the right connect command per cloud.

```text
Internet → AWS NLB (public Service :80) → public pods (Nginx)
        → /api + /health → internal pods (Node) → RDS (private)
```

The per-service Deployment/Service/HPA/PDB manifests are **rendered from
`stack.json`** by `kubernetes/scripts/render-manifests.sh` at deploy time — the
Kubernetes equivalent of the EC2 path emitting `docker-compose.yml`. Adding a
service to `stack.json` automatically gets a Deployment, a Service (public →
NLB, otherwise ClusterIP), an HPA and a PDB.

## Components

| Component | What it is |
| --------- | ---------- |
| **EKS control plane** | Managed Kubernetes API server. Private + public endpoint (public for `kubectl` from CI, tighten with `public_access_cidrs`). |
| **Managed node group** | EC2 instances (default `t3.medium`, 2–4) in the **private app subnets**. Runs the pods. |
| **Namespace `secure-ntier`** | Everything the app owns lives here - clean blast radius. |
| **Public Service** | `type: LoadBalancer` → AWS provisions an NLB fronting the public pods on `:80` (the single `public: true` service in `stack.json`). |
| **Public Deployment** | The exact same Nginx image as the EC2 path: serves the SPA and proxies `/api` + `/health` to the backend Service. |
| **Internal Services** | ClusterIP - internal only. Nginx proxies to `<service>:<port>` exactly like Docker Compose. |
| **Internal Deployments** | Node/Express with readiness (`/health`) + liveness (`/health`) probes. |
| **`app-config` ConfigMap** | Non-secret config shared by every service (`NODE_ENV`, pool size). `PORT` comes from `stack.json` per Deployment. |
| **`app-db-secret` Secret** | DB credentials + JWT secret. **Materialized at deploy time from AWS Secrets Manager** - never stored in Git. |
| **HPA (per service)** | Scales each Deployment on CPU at 70% (mirrors the EC2 target-tracking policy). |
| **PDB (per service)** | `minAvailable: 1` so node drains / cluster upgrades never drop both pods. |

## Security model

- **No secrets in Git.** `kubernetes/scripts/deploy.sh` reads the DB credentials
  + JWT secret from **AWS Secrets Manager** and creates the `app-db-secret`
  Kubernetes Secret at deploy time.
- **RDS stays private.** The DB security group only allows PostgreSQL from the
  app security group *and* the EKS cluster security group (added by the root
  module when `enable_eks = true`). Pods reach RDS through the node ENIs - no
  public exposure.
- **Least privilege.** The node group role only has the standard EKS worker,
  CNI, and ECR-read policies. The CI/CD principal gets an **EKS access entry**
  (cluster admin) to run `kubectl`; nothing else in the cluster trusts the
  internet.
- **Immutable images.** The exact image tested and Trivy-scanned in CI is the
  exact image deployed - tagged by git SHA, pulled from ECR.

## Scaling

- **Pods:** HPA (CPU at 70%, 2–6 replicas).
- **Nodes:** the managed node group auto-scales 2–4 on demand (EKS feature);
  the Cluster Autoscaler / Karpenter is a documented upgrade for finer control.

## Failure handling

| Failure | Self-healing |
| ------- | ------------ |
| Pod crash / OOM | Liveness probe → Kubelet restarts the container; Deployment keeps the replica count. |
| Node dies | EKS relaunches the instance; the PDB guarantees at least 1 pod is schedulable. |
| AZ fails | Pods + nodes run across the two private app subnets (AZs); RDS remains the single dependency (multi-AZ in prod). |
| Bad image deployed | `kubectl rollout undo` re-points to the previous revision. |

## Production upgrades

1. **HTTPS + AWS WAF** at the edge: install the AWS Load Balancer Controller and
   use an `Ingress` with ACM TLS + a WAF web ACL instead of the plain NLB
   Service.
2. **IRSA / External Secrets Operator**: replace pipeline-materialized secrets
   with IAM roles for service accounts or the Secrets Store CSI driver so
   secrets never transit CI.
3. **Cluster Autoscaler / Karpenter** for node scaling tied to HPA.
4. **OIDC** instead of static CI keys.

## See also

- Manifests: [`kubernetes/`](../../kubernetes/README.md)
- Provisioning: [`docs/deployment/eks.md`](../deployment/eks.md)
- Decision record: [`docs/adr/ADR-008-eks.md`](../adr/ADR-008-eks.md)