# Argo CD / GitOps

Reference commands for Argo CD - the GitOps continuous delivery tool for Kubernetes.

## Installation

```bash
# macOS
brew install argocd

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y argocd

# Or install via kubectl plugin
kubectl plugin install argocd

# Or download from https://argo-cd.getbootstrap.io/

# Verify
argocd version
```

## Version Check

```bash
argocd version
```

## Authentication

```bash
# Login (interactive, opens browser)
argocd login <argocd-server-url>

# Example:
argocd login argocd.example.com

# Login with token (non-interactive)
argocd login argocd.example.com --auth-token <token>

# Logout
argocd logout

# Context
argocd account update-password   # Update password

# This project's Argo CD would connect to the Argo CD instance
# deployed as part of the CI/CD pipeline
```

## Application Management

```bash
# List applications
argocd app list

# Get application details
argocd app get <application-name>

# Example:
argocd app get secure-ntier

# Sync application
argocd app sync <application-name>

# With dry-run (show differences without applying)
argocd app sync secure-ntier --dry-run

# Auto-sync
argocd app app set secure-ntier --auto-sync

# Delete application
argocd app delete <application-name>

# This project's GitOps workflow:
# Git (code) → CI/CD → Container Registry → Argo CD → Kubernetes
```

## Diff & History

```bash
# Show differences between live and desired state
argocd app diff <application-name>

# Show application history
argocd app history <application-name>

# Show specific revision
argocd app history secure-ntier --max 5

# This helps understand:
# - What changed between deployments
# - Rollback history
# - Deployment cadence
```

## Cluster & Health

```bash
# List all applications in all namespaces
argocd app list --all-namespaces

# Check application health
argocd app get secure-ntier -o yaml  # Full YAML includes health status

# Short health check
argocd app get secure-ntier -o json | jq .status.health

# This project would use Argo CD for:
# - Progressive delivery / canary deployments
# - Automated sync from Git
# - UI for visualizing live state vs desired state
```

## CLI Helpers

```bash
# Port-forward to UI (no external load balancer needed)
argocd port-forward app <application-name> 8080:80

# Example:
argocd port-forward app secure-ntier 8080:80

# Open in browser: http://localhost:8080

# Expose via LoadBalancer (if using Argo CD installed via Helm)
# kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# This project documents Argo CD as a GitOps option
# Primary deployment path: GitHub Actions + Terraform
```

## Troubleshooting

```bash
# Common issues
# "argocd: command not found" - install argocd
# "connection refused" - ensure Argo CD server is running
# "authentication failed" - re-run argocd login
# "application not found" - verify name and namespace

# Debug
argocd login --verbose    # Verbose output
argocd app get --verbose  # Detailed application status

# This project's primary path: GitHub Actions + Terraform
# Argo CD is documented as a GitOps option
```