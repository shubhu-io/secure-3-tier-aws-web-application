#!/usr/bin/env bash
# ============================================================================
# undeploy.sh - remove the application from the Kubernetes cluster.
# Usage: bash kubernetes/scripts/undeploy.sh <region> [cluster]
# ============================================================================
set -euo pipefail

REGION="${1:?usage: undeploy.sh <region> [cluster]}"
CLUSTER="${2:-secure-ntier-dev-eks}"

echo ">>> Configuring kubeconfig for ${CLUSTER} in ${REGION}"
aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"

echo ">>> Deleting the secure-ntier namespace (all app resources)"
kubectl delete namespace secure-ntier

echo ">>> Done."
