#!/usr/bin/env bash
# ============================================================================
# build-and-push.sh - build a Docker image and push it to AWS ECR.
# Usage: bash cicd/scripts/build-and-push.sh <service> <tag> <region> <project> <env> [dockerfile]
# Example: bash cicd/scripts/build-and-push.sh backend 1a2b3c4d ap-south-1 secure-ntier dev
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

REPO_KEY="${1:?usage: build-and-push.sh <service> <tag> <region> <project> <env> [dockerfile]}"
TAG="${2:?tag (e.g. git sha) required}"
REGION="${3:?region required}"
PROJECT="${4:-secure-ntier}"
ENV_NAME="${5:-dev}"
DOCKERFILE="${6:-docker/${REPO_KEY}/Dockerfile}"

CLOUD="$("$INFO" cloud)"
REGISTRY="$(resolve_registry "$CLOUD" "$REGION")"
REPO_PATH="$(repo_path "$CLOUD" "$REPO_KEY" "$PROJECT" "$ENV_NAME")"
URI="${REGISTRY}/${REPO_PATH}"

echo ">>> Building ${URI}:${TAG} (${CLOUD})"
docker build -f "$DOCKERFILE" -t "${URI}:${TAG}" -t "${URI}:latest" .

echo ">>> Pushing ${URI}:${TAG} and :latest"
docker push "${URI}:${TAG}"
docker push "${URI}:latest"

echo ">>> Pushed ${URI}:${TAG}"
