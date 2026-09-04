# Kubernetes (EKS) Infrastructure Screenshots

This folder contains verification captures for the optional container orchestration tier running on Amazon Elastic Kubernetes Service (EKS) in `ap-south-1`.

---

## 📋 Recommended Captures

| Filename | Description | Context |
|---|---|---|
| `01-eks-cluster.png` | AWS EKS console showing cluster in `ACTIVE` state with multi-AZ node groups | Control Plane Health |
| `02-kubectl-get-pods.png` | `kubectl get pods -n secure-ntier` output confirming healthy frontend/backend pods | Pod Lifecycle |
| `03-kubectl-get-svc.png` | `kubectl get svc` displaying AWS Load Balancer Controller hostname assignment | Ingress Routing |
| `04-hpa-pdb.png` | `kubectl get hpa` and `pdb` verifying autoscaling thresholds and disruption budgets | Resilience |

Refer to [`docs/deployment/eks.md`](../../docs/deployment/eks.md) for full Kubernetes deployment manifests and Helm instructions.
