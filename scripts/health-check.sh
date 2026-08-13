#!/usr/bin/env bash
# ============================================================================
# health-check.sh - verify the running application (local or AWS)
# Usage:
#   bash scripts/health-check.sh                  # default http://localhost
#   bash scripts/health-check.sh https://app.example.com
# ============================================================================
set -uo pipefail

BASE_URL="${1:-http://localhost}"

echo "==> Health check against ${BASE_URL}"
echo ""

code="$(curl -s -o /tmp/health.json -w '%{http_code}' "$BASE_URL/health" 2>/dev/null || true)"

echo "  GET /health -> HTTP $code"
if [ "$code" = "200" ]; then
  echo "  body: $(cat /tmp/health.json)"
  if grep -q '"db":"connected"' /tmp/health.json; then
    echo "  RESULT: PASS (backend reachable, database connected)"
    exit 0
  fi
  echo "  RESULT: WARN (backend up, database NOT connected)"
  exit 1
fi

echo "  RESULT: FAIL (no healthy response)"
exit 1
