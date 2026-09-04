#!/usr/bin/env bash
# ============================================================================
# registry-login.sh - authenticate Docker to the ACTIVE cloud's container
# registry (Amazon ECR | Azure Container Registry | GCP Artifact Registry).
#
# Usage: bash cicd/scripts/registry-login.sh <region>
#
# Cloud selection: CLOUD env var (aws | azure | gcp, default aws), validated
# against stack.json's "clouds" list. ecr-login.sh remains as a thin CLOUD=aws
# wrapper for backward compatibility.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

REGION="${1:?usage: registry-login.sh <region>}"
CLOUD="$("$INFO" cloud)"

case "$CLOUD" in
  aws)
    # <account>.dkr.ecr.<region>.amazonaws.com - from terraform output /
    # CLOUD_REGISTRY_URL / account-id fallback (see cloud-lib.sh).
    REGISTRY="$(resolve_registry "$CLOUD" "$REGION")"
    aws ecr get-login-password --region "$REGION" |
      docker login --username AWS --password-stdin "$REGISTRY"
    ;;
  azure)
    REGISTRY="$(resolve_registry "$CLOUD" "$REGION")"
    az acr login --name "${REGISTRY%%.azurecr.io*}"
    ;;
  gcp)
    # configure-docker takes the HOST only (<region>-docker.pkg.dev); the
    # project part of registry_url (if present) is not part of it.
    REGISTRY="$(resolve_registry "$CLOUD" "$REGION")"
    REGISTRY="${REGISTRY%%/*}"
    gcloud auth configure-docker "$REGISTRY" --quiet
    ;;
  *)
    echo "ERROR: unsupported cloud '$CLOUD' (aws | azure | gcp)" >&2
    exit 1
    ;;
esac

echo "Logged in to ${CLOUD} registry: ${REGISTRY}"
