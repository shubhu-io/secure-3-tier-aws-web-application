#!/usr/bin/env bash
# ============================================================================
# seed-data.sh - Seed realistic sample data into local dev or staging app.
#
# Usage:
#   bash scripts/seed-data.sh [base_url]
# Example:
#   bash scripts/seed-data.sh http://localhost
# ============================================================================
set -euo pipefail

BASE_URL="${1:-http://localhost}"
EMAIL="${SEED_EMAIL:-dev@example.com}"
PASSWORD="${SEED_PASSWORD:-Password123!}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'; RED='\033[0;31m'
info()    { echo -e "${CYAN}[SEED]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }

info "Connecting to ${BASE_URL}..."

# 1. Register or Login
info "Authenticating developer user (${EMAIL})..."
TOKEN=""

LOGIN_RESP="$(curl -s -X POST "${BASE_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" || true)"

if echo "$LOGIN_RESP" | grep -q '"token"'; then
  TOKEN="$(echo "$LOGIN_RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)"
  success "Logged in existing user."
else
  REG_RESP="$(curl -s -X POST "${BASE_URL}/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" || true)"

  if echo "$REG_RESP" | grep -q '"token"'; then
    TOKEN="$(echo "$REG_RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)"
    success "Registered new developer account."
  else
    echo -e "${RED}[ERROR]${RESET} Failed to register or login: $REG_RESP" >&2
    exit 1
  fi
fi

# 2. Seed Sample Items
declare -a SAMPLE_ITEMS=(
  "Configure multi-cloud IAM policies|Audit AWS, Azure, and GCP least-privilege roles"
  "Verify ALB health check probe|Ensure target groups accurately monitor /health/ready"
  "Deploy ArgoCD sync application|Set up GitOps continuous delivery for staging cluster"
  "Run Chaos Engineering experiment|Simulate container failure to test auto-healing"
  "Configure CloudWatch Dashboard & Alarms|Set threshold alerts for ASG 5xx errors and CPU spikes"
)

info "Populating sample platform backlog items..."
COUNT=0
for ENTRY in "${SAMPLE_ITEMS[@]}"; do
  IFS="|" read -r TITLE DESC <<< "$ENTRY"
  RESP="$(curl -s -X POST "${BASE_URL}/api/items" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"${TITLE}\",\"description\":\"${DESC}\"}")"
  
  if echo "$RESP" | grep -q '"id"'; then
    COUNT=$((COUNT + 1))
    echo "  + Added: ${TITLE}"
  fi
done

echo ""
success "Seeding complete! Added ${COUNT} sample items."
info "Credentials for local login:"
echo "  Email:    ${EMAIL}"
echo "  Password: ${PASSWORD}"
