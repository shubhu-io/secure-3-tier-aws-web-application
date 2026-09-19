#!/usr/bin/env bash
# ============================================================================
# logs.sh - tail the logs of the running local stack.
#   bash docker/scripts/logs.sh                # follow all services
#   bash docker/scripts/logs.sh backend        # follow one service
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

exec bash "$ROOT/scripts/local-up.sh" --logs