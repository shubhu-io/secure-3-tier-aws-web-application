# Kubernetes (kubectl)

Reference commands for Kubernetes. This project supports optional EKS (AWS), AKS (Azure), and GKE (GCP) deployment.

## Installation

```bash
# macOS
brew install kubectl

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
curl -s https://storage.googleapis.com/kubernetes-release/release/stable/debian/x86_64/kubectl | sudo tee /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

# Windows: Download from kubernetes.io

# Or using scoop (Windows)
# scoop install kubectl

# Verify
kubectl version --client
```

## Version Check

```bash
kubectl version --client
kubectl version        # Server version too (if connected)
```

## Configuration

```bash
# View current context
kubectl config current-context

# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Add new cluster context
aws eks update-kubeconfig --name secure-ntier-dev-eks --region us-west-2  # AWS EKS

# Or AKS
az aks get-credentials --resource-group secure-ntier-rg --name secure-ntier-aks  # Azure AKS

# Or GKE
gcloud container clusters get-credentials my-cluster --region us-central1-a  # GCP GKE

# This project's Kubernetes manifests are under kubernetes/ directory
```

## Workload Inspection

```bash
# Get resources
kubectl get all                     # Show all resources in current namespace

# Show specific resource type
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get nodes
kubectl get namespaces

# Show detailed information
kubectl describe pod <pod-name>
kubectl describe deployment <deploy-name>
kubectl describe service <svc-name>
kubectl describe node <node-name>

# This project's Kubernetes manifests (kubernetes/):
# - namespace.yaml (secure-ntier namespace)
# - configmap.yaml (app config)
# - secret.yaml.example (DB secret template)
# - kustomization.yaml (static support resources)
# - render-manifests.sh (per-service Deployment/Service/HPA/PDB from stack.json)
```

## Pod Management

```bash
# Create from manifest
kubectl apply -f kubernetes/

# Delete pod
kubectl delete pod <pod-name>

# Delete deployment
kubectl delete deployment <deploy-name>

# Rollout status
kubectl rollout status deployment <deploy-name>

# Rollout history
kubectl rollout history deployment <deploy-name>

# Rollback to previous version
kubectl rollout undo deployment <deploy-name>

# This project uses rollout with HPA/PDB for availability
```

## Service & Ingress

```bash
# Create service
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/namespace.yaml

# List services
kubectl get services -n secure-ntier

# Describe service
kubectl describe service <svc-name> -n secure-ntier

# Port-forward to local access
kubectl port-forward pod/<pod-name> 8080:80

# This project's Kubernetes path:
# - NLB → frontend → backend → RDS (EKS path)
# - Optional, coexists with EC2/VMSS path
```

## Scaling

```bash
# Manual scale
kubectl scale deployment <deploy-name> --replicas=3

# Autoscaling (HPA)
kubectl autoscale deployment <deploy-name> --min=2 --max=5

# With CPU target
kubectl autoscale deployment <deploy-name> \
  --min=2 --max=5 --cpu-percent=70

# Pod Disruption Budget
kubectl edit pdb <pd-name> -n secure-ntier

# This project's HPA targets CPU > 70%, PDB minAvailable 1
```

## Debugging

```bash
# View logs
kubectl logs pod/<pod-name>

# Previous container logs (if restarted)
kubectl logs pod/<pod-name> --previous

# Exec into container
kubectl exec -it pod/<pod-name> -- bash

# Debug shell in running container
kubectl exec -it pod/<pod-name> -- sh

# Describe events
kubectl get events -n secure-ntier

# This project's troubleshooting:
# - kubectl get events          # Events in namespace
# - kubectl describe pod        # Pod details + reasons
# - kubectl logs                # Application logs
# - kubectl logs --previous     # Previous container logs
# - kubectl rollout status     # Deployment rollout status
```

## Node & Scheduling

```bash
# Describe node
kubectl describe node <node-name>

# Cordon node (drain for maintenance)
kubectl cordon <node-name>

# Drain node (with graceful disruption)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# This project uses private app subnets and NACLs for isolation
```

## Authentication & RBAC

```bash
# Check authorization
kubectl auth can-i list pods

# Check cluster role binding
kubectl get clusterrolebinding

# Check role binding
kubectl get rolebinding

# This project's RBAC:
# - namespace: secure-ntier
# - secrets mounted from AWS Secrets Manager
# - configmap for app config
```

## Troubleshooting

```bash
# Common issues
# "kubectl: command not found" - install kubectl
# "cannot connect to the API server" - check kubeconfig, network
# "resource mapping not found" - wrong API version
# "imagepullbackoff" - check ECR/ACR/Artifact Registry credentials

# Debug
kubectl cluster-info    # Show server info
kubectl get events      # Events in all namespaces
kubectl describe pod    # Detailed pod information

# This project's Kubernetes is optional (coexists with EC2/VMSS path)
# Manifests are rendered from stack.json via render-manifests.sh
```