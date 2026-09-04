#!/usr/bin/env bash
# ============================================================================
# verify.sh - one-command verification of the deployed AWS platform.
# Requires AWS credentials + terraform outputs available.
#
# Usage:
#   bash scripts/verify.sh <region> <project> <env> <alb_url>
#   bash scripts/verify.sh ap-south-1 secure-ntier dev http://...
# ============================================================================
set -uo pipefail

REGION="${1:?usage: verify.sh <region> <project> <env> <alb_url>}"
PROJECT="${2:?project required}"
ENV_NAME="${3:?env required}"
ALB_URL="${4:-http://localhost}"

echo "===== 1. ALB health check ====="
bash scripts/health-check.sh "$ALB_URL"

echo ""
echo "===== 2. Auto Scaling Group ====="
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name "${PROJECT}-${ENV_NAME}-asg" \
  --region "$REGION" \
  --query 'AutoScalingGroups[0].{MinSize:min_size,MaxSize:max_size,Desired:desired_capacity,Instances:length(Instances)}' \
  --output table

echo ""
echo "===== 3. RDS (must NOT be publicly accessible) ====="
aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier "${PROJECT}-${ENV_NAME}-db" \
  --query 'DBInstances[0].{PubliclyAccessible:PubliclyAccessible,MultiAZ:MultiAZ,StorageEncrypted:StorageEncrypted,Status:DBInstanceStatus}' \
  --output table

echo ""
echo "===== 4. CloudWatch alarms ====="
aws cloudwatch describe-alarms --region "$REGION" \
  --query "MetricAlarms[?contains(AlarmName, '${PROJECT}-${ENV_NAME}')].{Alarm:AlarmName,State:StateValue}" \
  --output table

echo ""
echo "===== 5. WAF web ACL ====="
aws wafv2 list-web-acls --scope REGIONAL --region "$REGION" \
  --query "WebACLs[?contains(Name, '${PROJECT}-${ENV_NAME}')].{Name:Name,ARN:ARN}" \
  --output table

echo ""
echo "===== 6. ECR repositories ====="
aws ecr describe-repositories --region "$REGION" \
  --query "repositories[?contains(repositoryName, '${PROJECT}-${ENV_NAME}')].repositoryName" \
  --output table

echo ""
echo "===== 7. SSM deploy parameters ====="
aws ssm get-parameter --name "/${PROJECT}/${ENV_NAME}/backend-image" --region "$REGION" --query 'Parameter.Value' --output text

echo ""
echo "===== Verification complete ====="
