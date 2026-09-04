# GitOps with Argo CD (optional)

Optional pull-based deployment path alongside the push-based pipelines.
Argo CD watches this repository and reconciles the **static Kubernetes
support resources** (`namespace`, `configmap`) plus, if you switch the
source below, the Helm chart.

## Why "prune: false"

Per-service Deployment/Service/HPA/PDB manifests are rendered at deploy time
from `stack.json` by `kubernetes/scripts/render-manifests.sh` and are not
committed to git. Argo therefore manages only what lives in the repo. To make
Argo fully declarative, point `spec.source.path` at
`helm/secure-ntier-platform` using a Helm source:

```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/secure-ntier-cloud-platform.git
  targetRevision: main
  path: helm/secure-ntier-platform
  helm:
    valuesObject:
      image:
        registry: <account>.dkr.ecr.ap-south-1.amazonaws.com
        tag: main-abc1234
      backend:
        env:
          DB_HOST: <rds-endpoint>
```

## Install

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
argocd app list && argocd app get secure-ntier
```

## Push vs pull

| | GitHub Actions / Jenkins (push) | Argo CD (pull) |
| --- | --- | --- |
| Trigger | commit to main | continuous reconciliation |
| Credentials | CI needs cloud credentials | cluster pulls from git only |
| Drift repair | none | selfHeal reverts manual changes |
| Rollback | re-run previous tag | `argocd app rollback secure-ntier` |

Keep one system authoritative for a workload to avoid fighting updates.
