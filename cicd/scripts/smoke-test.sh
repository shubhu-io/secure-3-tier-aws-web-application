#!/usr/bin/env bash
# ============================================================================
# smoke-test.sh - wait until the ALB returns a healthy /health response
# Usage:
#   ALB_URL="http://..." ATTEMPTS="36" bash cicd/scripts/smoke-test.sh
# ============================================================================
set -uo pipefail

ALB_URL="${ALB_URL:?set ALB_URL env var (e.g. https://app.example.com)}"
ATTEMPTS="${ATTEMPTS:-36}"

echo ">>> Smoke testing ${ALB_URL} (up to ${ATTEMPTS} attempts)"

for i in $(seq 1 "$ATTEMPTS"); do
  code="$(curl -s -o /tmp/smoke.json -w '%{http_code}' "$ALB_URL/health" 2>/dev/null || true)"
  body="$(cat /tmp/smoke.json 2>/dev/null || echo '{}')"
  db="$(printf '%s' "$body" | grep -o '"db":"[a-z]*"' || true)"

  echo "attempt $i: HTTP $code $db"

  if [ "$code" = "200" ] && printf '%s' "$db" | grep -q 'connected'; then
    echo ">>> Smoke test PASSED"
    exit 0
  fi

  sleep 10
done

echo "!!! Smoke test FAILED: ${ALB_URL}/health did not become healthy"
exit 1
