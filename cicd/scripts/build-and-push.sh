#!/usr/bin/env bash
# ============================================================================
# build-and-push.sh - build a Docker image and push it to Amazon ECR
# Usage: bash cicd/scripts/build-and-push.sh <service> <tag> <region> <project> <env> [dockerfile]
# Example: bash cicd/scripts/build-and-push.sh backend 1a2b3c4d eu-west-1 secure-ntier dev
#   [dockerfile] defaults to docker/<service>/Dockerfile; stack-push.sh always
#   passes the exact path from stack.json so any layout works.
# ============================================================================
set -euo pipefail

REPO_KEY="${1:?usage: build-and-push.sh <service> <tag> <region> <project> <env> [dockerfile]}"
TAG="${2:?tag (e.g. git sha) required}"
REGION="${3:?region required}"
PROJECT="${4:-secure-ntier}"
ENV_NAME="${5:-dev}"
DOCKERFILE="${6:-docker/${REPO_KEY}/Dockerfile}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}-${ENV_NAME}-${REPO_KEY}"

echo ">>> Building ${URI}:${TAG}"
docker build -f "$DOCKERFILE" -t "${URI}:${TAG}" -t "${URI}:latest" .

echo ">>> Pushing ${URI}:${TAG} and :latest"
docker push "${URI}:${TAG}"
docker push "${URI}:latest"

echo ">>> Pushed ${URI}:${TAG}"
