#!/usr/bin/env bash
# ============================================================================
# common.sh - shared helpers for docker/scripts/*.sh
# Source (not execute) from the other scripts in this folder:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
#
# Exports docker/.env overrides into the current shell so docker compose
# interpolation sees them regardless of the location the script is run from.
# ============================================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$ROOT/docker/docker-compose.yml"
COMPOSE_PROD_FILE="$ROOT/docker/docker-compose.prod.yml"
DOCKER_ENV="$ROOT/docker/.env"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
die()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

require_docker() {
  command -v docker &>/dev/null || die "Docker not found. Install Docker Desktop."
  docker compose version &>/dev/null || die "Docker Compose plugin not found."
}

# Export docker/.env into the shell so compose ${VAR} interpolation works.
load_env() {
  if [[ -f "$DOCKER_ENV" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$DOCKER_ENV"
    set +a
  fi
}