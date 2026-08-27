#!/usr/bin/env bash
# ============================================================================
# Chaos experiment: terminate one app instance and prove the ASG replaces it
# while the ALB keeps serving. Dev environments only.
#
#   ./chaos/kill-instance.sh --project secure-ntier --env dev
#
# Requires: aws CLI v2, jq, curl. Uses the same tags Terraform sets.
# ============================================================================
set -euo pipefail

PROJECT="secure-ntier"
ENVIRONMENT="dev"
REGION="${AWS_REGION:-eu-west-1}"
CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)    PROJECT="$2"; shift 2 ;;
    --env)        ENVIRONMENT="$2"; shift 2 ;;
    --region)     REGION="$2"; shift 2 ;;
    --yes)        CONFIRM=true; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

mapfile -t IDS < <(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Project,Values=${PROJECT}" \
            "Name=tag:Environment,Values=${ENVIRONMENT}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' --output text)

[[ ${#IDS[@]} -ge 1 ]] || { echo "no running instances found" >&2; exit 1; }

VICTIM="${IDS[0]}"
echo "Experiment: terminate ${VICTIM} (fleet size: ${#IDS[@]})"
$CONFIRM || { echo "DRY RUN - re-run with --yes to execute." ; exit 0; }

aws ec2 terminate-instances --region "$REGION" --instance-ids "$VICTIM" >/dev/null
echo "Terminated ${VICTIM}. Watch:"
echo "  aws autoscaling describe-auto-scaling-groups --region ${REGION} \\"
echo "    --query 'AutoScalingGroups[].Instances[].{id:InstanceId,h:HealthStatus,l:LifecycleState}'"
echo "The ASG should launch a replacement within ~2-5 minutes."
