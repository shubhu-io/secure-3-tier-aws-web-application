#!/usr/bin/env bash
# ============================================================================
# deploy-eks.sh - DEPRECATED alias for deploy-k8s.sh (kept for backward
# compatibility). Forces CLOUD=aws; new pipelines should call
# cicd/scripts/deploy-k8s.sh directly (it also handles AKS / GKE).
# Usage: bash cicd/scripts/deploy-eks.sh <tag> <region> <env> <project> [cluster]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> deploy-eks.sh is deprecated - delegating to deploy-k8s.sh (CLOUD=aws)"
CLOUD=aws exec bash "$SCRIPT_DIR/deploy-k8s.sh" "$@"
