#!/usr/bin/env bash
# ============================================================================
# cloud-lib.sh - helpers shared by the multi-cloud cicd/scripts.
#
# NOT runnable directly - source it:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   # shellcheck source=cloud-lib.sh
#   . "$SCRIPT_DIR/cloud-lib.sh"
#
# Conventions used by every script in this directory:
#   CLOUD               active cloud (aws | azure | gcp); default aws,
#                       validated against stack.json via stack-info.sh cloud
#   CLOUD_REGISTRY_URL  optional override for the container registry base URL
# ============================================================================
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$LIB_DIR/../.." && pwd)"

# resolve_registry <cloud> <region>
# Prints the registry base URL. Resolution order: CLOUD_REGISTRY_URL env
# override > `terraform output registry_url` > per-cloud CLI fallback.
resolve_registry() {
  local cloud="$1" region="$2" registry=""

  if [ -n "${CLOUD_REGISTRY_URL:-}" ]; then
    echo "$CLOUD_REGISTRY_URL"
    return 0
  fi

  if command -v terraform >/dev/null 2>&1; then
    registry="$(terraform -chdir="$REPO_ROOT/terraform" output -raw registry_url 2>/dev/null || true)"
  fi

  if [ -z "$registry" ]; then
    case "$cloud" in
      aws)
        local account_id="${AWS_ACCOUNT_ID:-}"
        [ -n "$account_id" ] || account_id="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
        registry="${account_id}.dkr.ecr.${region}.amazonaws.com"
        ;;
      azure)
        registry="$(az acr list --query '[0].loginServer' -o tsv 2>/dev/null | tr -d '\r' || true)"
        ;;
      gcp)
        local gcp_project="${GCP_PROJECT:-}"
        [ -n "$gcp_project" ] || gcp_project="$(gcloud config get-value project 2>/dev/null | tr -d '\r' || true)"
        registry="${region}-docker.pkg.dev/${gcp_project}"
        ;;
    esac
  fi

  [ -n "$registry" ] || {
    echo "ERROR: could not resolve the ${cloud} registry URL - set CLOUD_REGISTRY_URL or authenticate the cloud CLI" >&2
    return 1
  }
  echo "$registry"
}

# repo_path <cloud> <service> <project> <env>
# Per-service repository path under the registry base URL, matching what the
# Terraform modules create: ECR / Artifact Registry use "<project>-<env>-<svc>",
# ACR repositories are created on first push named after the service itself.
repo_path() {
  local cloud="$1" svc="$2" project="$3" env_name="$4"
  case "$cloud" in
    azure) echo "$svc" ;;
    *)     echo "${project}-${env_name}-${svc}" ;;
  esac
}
