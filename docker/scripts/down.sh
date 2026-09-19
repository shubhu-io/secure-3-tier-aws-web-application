#!/usr/bin/env bash
# ============================================================================
# down.sh - stop and remove the local stack containers.
#   bash docker/scripts/down.sh
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

exec bash "$ROOT/scripts/local-up.sh" --down