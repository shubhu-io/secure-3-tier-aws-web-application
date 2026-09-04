#!/usr/bin/env bash
# ============================================================================
# Chaos experiment: reboot the RDS instance (dev only!) and verify the app
# degrades gracefully - /health flips to db:disconnected, no crash-loop -
# then recovers automatically once the DB is back.
#
#   ./chaos/db-outage.sh --db-identifier secure-ntier-dev-postgres --yes
# ============================================================================
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
DB_ID=""
CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db-identifier) DB_ID="$2"; shift 2 ;;
    --region)        REGION="$2"; shift 2 ;;
    --yes)           CONFIRM=true; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$DB_ID" ]] || { echo "usage: $0 --db-identifier <rds-id>" >&2; exit 1; }

STATE=$(aws rds describe-db-instances --region "$REGION" \
  --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].DBInstanceStatus' --output text)

echo "Experiment: reboot ${DB_ID} (current state: ${STATE})"
echo "WARNING: expect ~60s of database unavailability. Dev only."
$CONFIRM || { echo "DRY RUN - re-run with --yes to execute."; exit 0; }

aws rds reboot-db-instance --region "$REGION" --db-instance-identifier "$DB_ID"
echo "Reboot issued. While it runs, poll the app:"
echo "  watch -n5 'curl -s https://<alb>/health'"
echo "Expected: status ok + db:disconnected during outage, connected after."
