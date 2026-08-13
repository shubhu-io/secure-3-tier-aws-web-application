#!/usr/bin/env bash
# ============================================================================
# deploy.sh - local alternative to the CI/CD pipeline.
# Builds, pushes to ECR, points the SSM params at the new images and starts
# a rolling instance refresh - exactly what deploy.yml does.
#
# Usage:
#   bash scripts/deploy.sh <tag> <region> <project> <env>
#   bash scripts/deploy.sh my-release-1 eu-west-1 secure-ntier dev
# ============================================================================
set -euo pipefail

TAG="${1:?usage: deploy.sh <tag> <region> <project> <env>}"
REGION="${2:?region required}"
PROJECT="${3:-secure-ntier}"
ENV_NAME="${4:-dev}"

bash cicd/scripts/ecr-login.sh "$REGION"
bash cicd/scripts/build-and-push.sh backend "$TAG" "$REGION" "$PROJECT" "$ENV_NAME"
bash cicd/scripts/build-and-push.sh frontend "$TAG" "$REGION" "$PROJECT" "$ENV_NAME"
bash cicd/scripts/deploy-ec2.sh "$TAG" "$REGION" "$ENV_NAME" "$PROJECT"

echo ""
echo ">>> Deployment triggered. Track it with:"
echo "    aws autoscaling describe-instance-refreshes --auto-scaling-group-name ${PROJECT}-${ENV_NAME}-asg --region $REGION"
