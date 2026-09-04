#!/usr/bin/env bash
# ============================================================================
# local-up.sh  –  Start the full stack locally with Docker Compose
#
# Requires: docker, docker compose plugin
# No AWS credentials needed — uses a local PostgreSQL container.
#
# Usage:
#   bash scripts/local-up.sh          # start in background
#   bash scripts/local-up.sh --logs   # start and follow logs
#   bash scripts/local-up.sh --down   # stop and remove containers
#   bash scripts/local-up.sh --reset  # stop, remove volumes, start fresh
# ============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
die()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker/docker-compose.yml"
MODE="${1:-}"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║        secure-ntier  —  Local Dev Stack                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── Preflight ──────────────────────────────────────────────────────────────────
command -v docker &>/dev/null || die "Docker not found. Install Docker Desktop."
docker compose version &>/dev/null || die "Docker Compose plugin not found."
success "Docker OK"

# ── Handle flags ───────────────────────────────────────────────────────────────
case "$MODE" in
  --down)
    info "Stopping stack…"
    docker compose -f "$COMPOSE_FILE" down
    success "Stack stopped"
    exit 0
    ;;
  --reset)
    info "Resetting stack (removing volumes)…"
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
    info "Starting fresh…"
    docker compose -f "$COMPOSE_FILE" up --build -d
    success "Stack reset and started"
    exit 0
    ;;
  --logs)
    info "Starting stack and following logs…"
    docker compose -f "$COMPOSE_FILE" up --build
    exit 0
    ;;
esac

# ── Start in background ────────────────────────────────────────────────────────
info "Building and starting all services…"
docker compose -f "$COMPOSE_FILE" up --build -d

# ── Wait for health ────────────────────────────────────────────────────────────
info "Waiting for backend to be healthy…"
MAX=30; COUNT=0
until curl -sf http://localhost:3000/health | grep -q '"status":"ok"' 2>/dev/null; do
  COUNT=$((COUNT + 1))
  if [[ $COUNT -ge $MAX ]]; then
    echo ""
    die "Backend didn't become healthy after ${MAX}s. Check logs: docker compose -f docker/docker-compose.yml logs backend"
  fi
  printf "."
  sleep 2
done
echo ""
success "Backend healthy"

# ── Print summary ──────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           ✅  Local stack is running!                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "Frontend:   http://localhost"
info "Backend:    http://localhost:3000"
info "Health:     http://localhost:3000/health"
info "DB (local): localhost:5432  (user: app_user, db: appdb)"
echo ""
info "View logs:  docker compose -f docker/docker-compose.yml logs -f"
info "Stop:       bash scripts/local-up.sh --down"
info "Reset DB:   bash scripts/local-up.sh --reset"
