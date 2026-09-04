#!/usr/bin/env bash
# ============================================================================
# stack-push.sh - build + scan + push EVERY service in stack.json to the
# ACTIVE cloud's registry (ECR | ACR | Artifact Registry, selected by CLOUD).
#
# Thin wrapper over build-and-push.sh, looping over the manifest services so a
# new service needs no pipeline edits - just a stack.json entry.
#
# Usage: bash cicd/scripts/stack-push.sh <tag> <region> <project> <env>
# Example: bash cicd/scripts/stack-push.sh 1a2b3c4d ap-south-1 secure-ntier dev
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"

TAG="${1:?usage: stack-push.sh <tag> <region> <project> <env>}"
REGION="${2:?region required}"
PROJECT="${3:-$("$INFO" project)}"
ENV_NAME="${4:-dev}"

for SVC in $("$INFO" list); do
  DOCKERFILE=$("$INFO" field "$SVC" dockerfile)
  bash "$SCRIPT_DIR/build-and-push.sh" "$SVC" "$TAG" "$REGION" "$PROJECT" "$ENV_NAME" "$DOCKERFILE"
done

echo ""
echo "===== stack-push: all images pushed ====="