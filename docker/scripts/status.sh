#!/usr/bin/env bash
# ============================================================================
# status.sh - show running container status and mapped ports.
#   bash docker/scripts/status.sh
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

exec bash "$ROOT/scripts/local-up.sh" --status