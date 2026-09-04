# Helm — Packaged Kubernetes Deployment

Alternative to the raw manifests rendered from `stack.json`
(`kubernetes/scripts/render-manifests.sh`). Same workloads, same namespace,
same secret - packaged as a versioned, overridable chart for teams that
prefer `helm` as their deployment interface.

```text
helm/secure-ntier-platform/
+-- Chart.yaml          # chart metadata (v0.1.0, appVersion 1.0.0)
+-- values.yaml         # replicas, resources, autoscaling, ingress defaults
+-- templates/
    |   _helpers.tpl    # name/label/image helpers
    |   backend-deployment.yaml
    |   frontend-deployment.yaml
    |   services.yaml
    |   hpa.yaml        # CPU-targeted autoscaling per service
    |   poddisruptionbudgets.yaml
    |   configmap.yaml  # non-secret env config
    |   ingress.yaml    # optional HTTPS ingress (nginx or ALB annotations)
    +-- NOTES.txt       # post-install hints
```

## Install

```bash
# secrets first (or reuse the one created by kubernetes/scripts/deploy.sh)
kubectl create namespace secure-ntier
kubectl -n secure-ntier create secret generic app-db-secret \
  --from-literal=db-user=app_user \
  --from-literal=db-password='<password>' \
  --from-literal=jwt-secret='<32+ char secret>'

helm upgrade --install ntier helm/secure-ntier-platform \
  --namespace secure-ntier --create-namespace \
  --set image.registry=<account>.dkr.ecr.ap-south-1.amazonaws.com \
  --set image.tag=main-abc1234 \
  --set backend.env.DB_HOST=<rds-endpoint>
```

## Render locally without a cluster

```bash
helm template ntier helm/secure-ntier-platform \
  --set backend.env.DB_HOST=rds.internal > /tmp/rendered.yaml

helm lint helm/secure-ntier-platform
```

## Relationship to kubernetes/

| Concern | kubernetes/ (raw) | helm/ |
| ------- | ----------------- | ----- |
| Source of truth | stack.json via render script | values.yaml overrides |
| Best for | CI/CD pipeline deploys | manual/ops-driven releases |
| Upgrades | re-render + kubectl apply | helm upgrade (history + rollback) |

Both target the same namespace (`secure-ntier`) and secret
(`app-db-secret`); do not install both against the same cluster unless you
rename the release and disable duplicate HPA/PDB ownership.
