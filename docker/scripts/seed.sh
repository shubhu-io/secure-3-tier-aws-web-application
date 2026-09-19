#!/usr/bin/env bash
# ============================================================================
# seed.sh - seed sample users and backlog items into the running app.
#   bash docker/scripts/seed.sh               # default http://localhost
#   bash docker/scripts/seed.sh http://myhost
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

BASE_URL="${1:-http://localhost}"

exec bash "$ROOT/scripts/seed-data.sh" "$BASE_URL"