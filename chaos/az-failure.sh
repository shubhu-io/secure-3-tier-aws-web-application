#!/usr/bin/env bash
# ============================================================================
# Chaos experiment: simulate an AZ outage by terminating every app instance
# in ONE availability zone. The instance(s) in the surviving AZ must keep
# serving and the ASG must rebalance. Dev environments only.
#
#   ./chaos/az-failure.sh --project secure-ntier --env dev --yes
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

AZ=$(aws ec2 describe-availability-zones --region "$REGION" \
  --filters "Name=state,Values=available" \
  --query "AvailabilityZones[0].ZoneName" --output text)

IDS=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Project,Values=${PROJECT}" \
            "Name=tag:Environment,Values=${ENVIRONMENT}" \
            "Name=availability-zone,Values=${AZ}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' --output text)

[[ -n "${IDS// /}" ]] || { echo "no instances found in ${AZ}" >&2; exit 1; }
echo "Experiment: terminate all instances in ${AZ}:"
echo "${IDS}"
$CONFIRM || { echo "DRY RUN - re-run with --yes to execute."; exit 0; }

aws ec2 terminate-instances --region "$REGION" --instance-ids $IDS >/dev/null
echo "Terminated. Verify the other AZ keeps serving:"
echo "  curl -s https://<alb>/health     # keep polling - expect zero downtime"
echo "ASG rebalances by launching replacements across AZs (may take ~5 min)."
