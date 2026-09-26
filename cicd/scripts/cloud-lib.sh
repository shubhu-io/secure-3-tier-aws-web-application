# ============================================================================
# cloud-lib.sh - AWS container registry and repository helpers.
#
# NOT runnable directly - source it:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   # shellcheck source=cloud-lib.sh
#   . "$SCRIPT_DIR/cloud-lib.sh"
# ============================================================================
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$LIB_DIR/../.." && pwd)"

# resolve_registry [region]
# Prints the AWS ECR registry base URL. Resolution order: CLOUD_REGISTRY_URL
# override > `terraform output registry_url` > AWS CLI STS identity.
resolve_registry() {
  local region="${2:-${1:-ap-south-1}}"
  local registry=""

  if [ -n "${CLOUD_REGISTRY_URL:-}" ]; then
    echo "$CLOUD_REGISTRY_URL"
    return 0
  fi

  if command -v terraform >/dev/null 2>&1; then
    registry="$(terraform -chdir="$REPO_ROOT/terraform" output -raw registry_url 2>/dev/null || true)"
  fi

  if [ -z "$registry" ]; then
    local account_id="${AWS_ACCOUNT_ID:-}"
    [ -n "$account_id" ] || account_id="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
    registry="${account_id}.dkr.ecr.${region}.amazonaws.com"
  fi

  [ -n "$registry" ] || {
    echo "ERROR: could not resolve the AWS ECR registry URL - set CLOUD_REGISTRY_URL or configure AWS credentials" >&2
    return 1
  }
  echo "$registry"
}

# repo_path <cloud> <service> <project> <env>
# Per-service repository path matching what Terraform creates: "<project>-<env>-<svc>"
repo_path() {
  local cloud="$1" svc="$2" project="$3" env_name="$4"
  echo "${project}-${env_name}-${svc}"
}
