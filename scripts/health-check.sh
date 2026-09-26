#!/usr/bin/env bash
# ============================================================================
# health-check.sh - verify the running application (local or AWS)
# Usage:
#   bash scripts/health-check.sh                  # default http://localhost
#   bash scripts/health-check.sh https://app.example.com
# ============================================================================
set -uo pipefail

BASE_URL="${1:-http://localhost}"
TMP_RESP="$(mktemp 2>/dev/null || echo "/tmp/health_${RANDOM}.json")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${CYAN}==> Health Check Target: ${BOLD}${BASE_URL}${RESET}"

# Perform curl with HTTP code and total response time measurement
STATS="$(curl -s -o "$TMP_RESP" -w '%{http_code}|%{time_total}' "${BASE_URL}/health" 2>/dev/null || echo "000|0.000")"
HTTP_CODE="$(echo "$STATS" | cut -d'|' -f1)"
TIME_TOTAL="$(echo "$STATS" | cut -d'|' -f2)"

BODY=""
if [ -f "$TMP_RESP" ]; then
  BODY="$(cat "$TMP_RESP")"
  rm -f "$TMP_RESP"
fi

echo -e "  HTTP Status: ${BOLD}${HTTP_CODE}${RESET} | Response Time: ${BOLD}${TIME_TOTAL}s${RESET}"

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "  Response:    ${BODY}"
  if echo "$BODY" | grep -q '"db":"connected"'; then
    echo -e "  ${GREEN}${BOLD}✔ RESULT: PASS${RESET} (Backend reachable, MySQL connected)"
    exit 0
  else
    echo -e "  ${YELLOW}${BOLD}⚠ RESULT: WARN${RESET} (Backend up, but database is not connected)"
    exit 1
  fi
fi

echo -e "  ${RED}${BOLD}✘ RESULT: FAIL${RESET} (Service unavailable or returned HTTP ${HTTP_CODE})"
exit 1


