#!/usr/bin/env bash
# ============================================================================
# Chaos experiment: stop the backend container on one app instance via SSM
# (no SSH needed) and prove the ALB health check pulls the target, then the
# fleet converges again. Dev environments only.
#
#   ./chaos/stop-container.sh --project secure-ntier --env dev --yes
# ============================================================================
set -euo pipefail

PROJECT="secure-ntier"
ENVIRONMENT="dev"
REGION="${AWS_REGION:-eu-west-1}"
CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --env)     ENVIRONMENT="$2"; shift 2 ;;
    --region)  REGION="$2"; shift 2 ;;
    --yes)     CONFIRM=true; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

TARGET=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Project,Values=${PROJECT}" \
            "Name=tag:Environment,Values=${ENVIRONMENT}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)

[[ "$TARGET" != "None" ]] || { echo "no instances found" >&2; exit 1; }
echo "Experiment: stop 'backend' compose service on ${TARGET}"
$CONFIRM || { echo "DRY RUN - re-run with --yes to execute."; exit 0; }

CMD_ID=$(aws ssm send-command --region "$REGION" \
  --instance-ids "$TARGET" \
  --document-name "AWS-RunShellScript" \
  --comment "chaos: stop backend container" \
  --parameters 'commands=["cd /opt/app && docker compose stop backend"]' \
  --query 'Command.CommandId' --output text)

echo "SSM command ${CMD_ID} sent. Expected sequence:"
echo "  1. ALB health checks fail -> target drained (~30s)"
echo "  2. docker compose restart policy brings it back"
echo "  3. target returns to healthy"
echo ""
echo "Poll: aws ssm wait command-executed --command-id ${CMD_ID} --instance-id ${TARGET} --region ${REGION}"
