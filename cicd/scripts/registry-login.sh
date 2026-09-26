#!/usr/bin/env bash
# ============================================================================
# registry-login.sh - authenticate Docker to Amazon ECR.
# Usage: bash cicd/scripts/registry-login.sh [region]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

REGION="${1:-ap-south-1}"
REGISTRY="$(resolve_registry "aws" "$REGION")"

echo "Logging in to Amazon ECR (${REGISTRY})..."
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY"

echo "Successfully logged in to AWS ECR registry: ${REGISTRY}"
