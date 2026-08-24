#!/usr/bin/env bash
# ============================================================================
# ecr-login.sh - DEPRECATED alias for registry-login.sh (kept for backward
# compatibility). Forces CLOUD=aws; new pipelines should call
# cicd/scripts/registry-login.sh directly.
# Usage: bash cicd/scripts/ecr-login.sh <region>
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> ecr-login.sh is deprecated - delegating to registry-login.sh (CLOUD=aws)"
CLOUD=aws exec bash "$SCRIPT_DIR/registry-login.sh" "$@"
