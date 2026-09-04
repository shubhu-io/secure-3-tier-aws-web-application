#!/usr/bin/env bash
# ============================================================================
# End-to-end test: local stack -> backend API through nginx -> PostgreSQL.
# Requires the local docker compose stack to be running.
# Usage:
#   docker compose up -d --build   (in docker/)
#   bash tests/integration/e2e.sh
# ============================================================================
set -uo pipefail

URL="${1:-http://localhost}"

echo "==> E2E against $URL"

bash tests/application/integration.sh "$URL" || {
  echo "Application integration failed."
  exit 1
}

echo ""
echo "==> E2E PASS"
