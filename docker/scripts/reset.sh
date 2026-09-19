#!/usr/bin/env bash
# ============================================================================
# reset.sh - stop, wipe the database volume and start the stack fresh.
#   bash docker/scripts/reset.sh
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

exec bash "$ROOT/scripts/local-up.sh" --reset