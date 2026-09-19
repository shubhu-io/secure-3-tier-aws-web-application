#!/usr/bin/env bash
# ============================================================================
# up.sh - build & start the local stack and wait for health.
#
#   bash docker/scripts/up.sh             # start in background
#   bash docker/scripts/up.sh --logs      # start and follow logs
#   bash docker/scripts/up.sh --seed      # start, wait for health, seed data
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

exec bash "$ROOT/scripts/local-up.sh" "$@"