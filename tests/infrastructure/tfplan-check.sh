#!/usr/bin/env bash
# ============================================================================
# Infrastructure test: the terraform plan must contain the critical resources.
# Usage: bash tests/infrastructure/tfplan-check.sh
# Requires AWS credentials and an initialised backend.
# ============================================================================
set -euo pipefail

ENV_FILE="${1:-environments/dev/terraform.tfvars}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT/terraform"

# Resolve terraform binary (Windows Git Bash compat)
TF_BIN="${TERRAFORM_BIN:-}"
if [ -z "$TF_BIN" ]; then
  if command -v terraform >/dev/null 2>&1; then TF_BIN="terraform"
  elif command -v terraform.exe >/dev/null 2>&1; then TF_BIN="terraform.exe"
  elif [ -x "/c/terraform/terraform.exe" ]; then TF_BIN="/c/terraform/terraform.exe"
  elif [ -x "C:/terraform/terraform.exe" ]; then TF_BIN="C:/terraform/terraform.exe"
  else TF_BIN="terraform"; fi
fi

echo "==> terraform plan ($TF_BIN)"
"$TF_BIN" plan -var-file="$ENV_FILE" -out=/tmp/tfplan.bin >/dev/null

echo "==> Extracting resource addresses"
"$TF_BIN" show -json /tmp/tfplan.bin > /tmp/tfplan.json

REQUIRED=(
  "aws_vpc.this"
  "aws_subnet.public"
  "aws_subnet.app"
  "aws_subnet.db"
  "aws_internet_gateway.this"
  "aws_nat_gateway.this"
  "aws_route_table.public"
  "aws_route_table.app"
  "aws_route_table.db"
  "aws_security_group.alb"
  "aws_security_group.app"
  "aws_security_group.db"
  "aws_lb.this"
  "aws_lb_target_group.app"
  "aws_launch_template.this"
  "aws_autoscaling_group.this"
  "aws_db_instance.this"
  "aws_ecr_repository.this"
  "aws_wafv2_web_acl.this"
  "aws_cloudwatch_metric_alarm.asg_cpu_high"
  "aws_sns_topic.alerts"
  "aws_flow_log.this"
  "aws_cloudtrail.this"
)

FAIL=0
for addr in "${REQUIRED[@]}"; do
  if rg -q "\"type\":\"${addr%%.*}\".*\"name\":\"${addr##*.}\"" /tmp/tfplan.json; then
    echo "  [OK]   $addr"
  else
    echo "  [MISS] $addr"
    FAIL=1
  fi
done

if [ "$FAIL" = "1" ]; then
  echo "==> FAIL: some critical resources are missing from the plan"
  exit 1
fi

echo "==> PASS: all critical resources are in the plan"
