#!/usr/bin/env bash
# ============================================================================
# cleanup.sh - guide for safely tearing down the platform.
#
# Step 1 destroys everything Terraform manages. Step 2 lists resources that
# need MANUAL cleanup because Terraform does not (or should not) remove them.
#
# Usage:
#   bash scripts/cleanup.sh <region> <project> <env>
#   bash scripts/cleanup.sh eu-west-1 secure-ntier dev
# ============================================================================
set -uo pipefail

REGION="${1:?usage: cleanup.sh <region> <project> <env>}"
PROJECT="${2:?project required}"
ENV_NAME="${3:?env required}"

echo "==> WARNING: this will DESTROY the ${ENV_NAME} environment in ${REGION}"
read -r -p "Type the environment name to confirm (${ENV_NAME}): " confirm
if [ "$confirm" != "$ENV_NAME" ]; then
  echo "Aborted."
  exit 1
fi

# 1. Terraform destroy
cd terraform
terraform init -backend=false -input=false >/dev/null 2>&1 || true
terraform destroy \
  -var-file="environments/${ENV_NAME}/terraform.tfvars" \
  -auto-approve || echo "  (terraform destroy failed or was skipped - see below)"

cd ..

echo ""
echo "==> Manual cleanup checklist (not always removed by terraform destroy):"
echo "  [ ] S3 buckets (check / empty manually):"
echo "        ${PROJECT}-${ENV_NAME}-alb-logs"
echo "        ${PROJECT}-${ENV_NAME}-cloudtrail"
echo "        <your-org>-terraform-state"
echo "  [ ] Route 53 hosted zone (if created): $REGION -> Hosted zones"
echo "  [ ] CloudWatch log groups: /aws/vpc-flow-log/${PROJECT}-${ENV_NAME},"
echo "        /${PROJECT}-${ENV_NAME}/app"
echo "  [ ] CloudTrail + CloudWatch Logs in CloudTrail console"
echo "  [ ] Any RDS final snapshot named ${PROJECT}-${ENV_NAME}-final-*"
echo "        (keep it if you want disaster recovery of the data!)"
echo ""
echo "==> Done. Check the AWS Billing console to confirm charges have stopped."
