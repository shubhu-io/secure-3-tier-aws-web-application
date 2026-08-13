#!/usr/bin/env bash
# ============================================================================
# ecr-login.sh - authenticate Docker to Amazon ECR using the current AWS creds
# Usage: bash cicd/scripts/ecr-login.sh <region>
# ============================================================================
set -euo pipefail

REGION="${1:?usage: ecr-login.sh <region>}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

aws ecr get-login-password --region "$REGION" |
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Logged in to ECR: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
