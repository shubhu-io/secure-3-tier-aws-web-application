# Helm

Reference commands for Helm - the Kubernetes package manager. This project supports Helm for Kubernetes application deployment.

## Installation

```bash
# macOS
brew install helm

# Ubuntu/Debian
curl https://baltocdn.com/helm/signing/KEYS | gpg --pool-socket hkps://keyserver.ubuntu.com --keyserver-options auto-key-retrieve | gpg --import -
sudo apt-get install apt-transport-https
sudo snap install helm --classic

# Or using PowerShell (Windows)
# choco install helm

# Or download from https://helm.sh/

# Verify
helm version

# Or using winget (Windows 10+)
winget install helm
```

## Version Check

```bash
helm version                # Show client version (and server if connected)
helm version --short        # Compact version
```

## Repository Management

```bash
# Add a Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add this project's repo (if published)
helm repo add secure-ntier OCI_REGISTRY_URL

# Update repositories
helm repo update

# List repositories
helm repo list

# Remove repository
helm repo remove bitnami
```

## Chart Operations

```bash
# Install a chart
helm install my-release bitnami/redis

# Install with custom values
helm install my-release bitnami/redis -f values.yaml

# Install from OCI registry
helm install my-release oci://registry-1.docker.io/namespace/chart

# List releases
helm list   # Deprecated in Helm v3 (use:)

# List releases (Helm v3)
helm list --all.namespaces

# Or: helm history <release-name>

# Upgrade release
helm upgrade my-release bitnami/redis -f values.yaml

# Rollback release
helm rollback my-release        # Rollback to last release
helm rollback my-release 2      # Rollback to specific version (v2)

# Uninstall release
helm uninstall my-release

# This project's Helm usage:
# - Optional for Kubernetes deployment
# - Charts rendered from stack.json via render-manifests.sh
# - May manage EKS/AKS/GKE resources
```

## Chart Inspection

```bash
# Show chart information
helm search repo redis

# Search chart museum
helm search hub redis

# Lint chart (validate)
helm lint mychart/

# Show chart values
helm show values bitnami/redis

# Show chart templates
helm template my-release bitnami/redis

# This project documents Helm as a deployment option, not a primary packaging format
```

## Helm Architecture

```bash
# Helm consists of:
# - Helm CLI (client)
# - Tiller server (deprecated/removed in Helm v3)
# - Charts (packaged Kubernetes manifests)
# - Releases (installed versions of charts)

# Chart structure:
# Chart.yaml     # Metadata (name, version, description)
# values.yaml    # Configuration values
# templates/     # Kubernetes YAML manifests (templates using Go templating)

# This project's Kubernetes manifests are rendered from stack.json,
# not from Helm charts, but Helm is documented as an option
```

## Troubleshooting

```bash
# Common issues
# "helm: command not found" - install Helm
# "unable to build OCI client" - Helm v3 OCI support
# "release: not found" - check release name
# "could not find chart" - verify repo addition

# Debug
helm version --debug     # Debug output
helm install --debug    # Show what would be installed

# This project uses render-manifests.sh (Go templated manifests)
# rather than Helm charts, but Helm is documented as an option
```