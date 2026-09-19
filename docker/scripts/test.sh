#!/usr/bin/env bash
# ============================================================================
# test.sh - run the full local developer validation suite.
#   bash docker/scripts/test.sh               # default http://localhost
#   bash docker/scripts/test.sh http://myhost
#
# Requires the local stack to be running (up.sh first).
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

BASE_URL="${1:-http://localhost}"

exec bash "$ROOT/scripts/local-test.sh" "$BASE_URL"