#!/usr/bin/env bash
# ============================================================================
# deploy-ec2.sh - point the environment at the new images and refresh the ASG
# Usage: bash cicd/scripts/deploy-ec2.sh <tag> <region> <env> <project>
# ============================================================================
set -euo pipefail

TAG="${1:?usage: deploy-ec2.sh <tag> <region> <env> <project>}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-secure-ntier}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

# 1. Point the SSM "deploy pointer" parameters at the new images.
#    Instances read these values on boot and pull that image from ECR.
for repo in backend frontend; do
  URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}-${ENV_NAME}-${repo}"
  PARAM="/secure-ntier/${ENV_NAME}/${repo}-image"

  aws ssm put-parameter \
    --name "$PARAM" \
    --type String \
    --value "${URI}:${TAG}" \
    --overwrite \
    --region "$REGION" >/dev/null

  echo ">>> $PARAM = ${URI}:${TAG}"
done

# 2. Rolling instance refresh: replaces instances one by one so new
#    instances boot with the new images. Min 50% healthy during the swap.
ASG_NAME="${PROJECT}-${ENV_NAME}-asg"

aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --region "$REGION" \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":120}' \
  --query 'InstanceRefreshId' --output text

echo ">>> Instance refresh started on ${ASG_NAME}"
