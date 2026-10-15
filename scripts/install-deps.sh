#!/usr/bin/env bash
# ============================================================================
# install-deps.sh - one-shot automation to install EVERY project dependency.
#
# Installs:
#   1. Backend Node dependencies   (application/backend)
#   2. Frontend Node dependencies  (application/frontend)
#   3. Terraform providers/modules (terraform/cloud/aws)
#   4. Docker images (optional, --docker) + local stack build cache
#
# Usage:
#   bash scripts/install-deps.sh            # app + terraform
#   bash scripts/install-deps.sh --docker   # also build local docker images
#   bash scripts/install-deps.sh --clean    # wipe node_modules/.terraform first
#   bash scripts/install-deps.sh --ci       # npm ci (lockfile-exact) instead of npm install
# ============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/application/backend"
FRONTEND_DIR="$REPO_ROOT/application/frontend"
TF_DIR="$REPO_ROOT/terraform/cloud/aws"
COMPOSE_FILE="$REPO_ROOT/docker/docker-compose.yml"

DO_DOCKER=0
DO_CLEAN=0
NPM_CMD="install --no-audit --no-fund"

for arg in "$@"; do
  case "$arg" in
    --docker) DO_DOCKER=1 ;;
    --clean)  DO_CLEAN=1 ;;
    --ci)     NPM_CMD="ci --no-audit --no-fund" ;;
    -h|--help)
      grep '^#   ' "$0" | sed 's/^#   //'
      exit 0
      ;;
    *) die "Unknown option: $arg (try --help)" ;;
  esac
done

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      secure-ntier  —  Install All Dependencies           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 0. Preflight ──────────────────────────────────────────────────────────────
command -v node >/dev/null 2>&1 || die "Node.js not found. Install Node 20+ (see docs/deployment/prerequisites.md)."
command -v npm  >/dev/null 2>&1 || die "npm not found. Install Node 20+."

# ── 1. Application dependencies ───────────────────────────────────────────────
install_node_deps() {
  local name="$1" dir="$2"
  info "Installing ${name} dependencies (npm ${NPM_CMD%% *})…"
  [[ -d "$dir" ]] || die "Directory not found: $dir"
  if [[ "$DO_CLEAN" == "1" && -d "$dir/node_modules" ]]; then
    info "  cleaning $dir/node_modules"
    rm -rf "$dir/node_modules"
  fi
  (cd "$dir" && npm $NPM_CMD)
  success "${name} dependencies installed"
}

install_node_deps "backend"  "$BACKEND_DIR"
install_node_deps "frontend" "$FRONTEND_DIR"

# ── 2. Terraform providers + modules ──────────────────────────────────────────
if command -v terraform >/dev/null 2>&1; then
  info "Initializing Terraform (downloads providers + modules)…"
  [[ -d "$TF_DIR" ]] || die "Terraform dir not found: $TF_DIR"
  if [[ "$DO_CLEAN" == "1" && -d "$TF_DIR/.terraform" ]]; then
    info "  cleaning $TF_DIR/.terraform"
    rm -rf "$TF_DIR/.terraform"
  fi
  (cd "$TF_DIR" && terraform init -input=false -upgrade)
  success "Terraform providers initialized"
else
  warn "terraform not found - skipping provider init (install Terraform 1.5+)."
fi

# ── 3. Optional Docker images ─────────────────────────────────────────────────
if [[ "$DO_DOCKER" == "1" ]]; then
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    info "Building local Docker images…"
    docker compose -f "$COMPOSE_FILE" build
    success "Docker images built"
  else
    warn "Docker / Compose not available - skipping image build."
  fi
fi

# ── 4. Summary ────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         ✅  All dependencies installed!                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "Next steps:"
info "  Start local stack : bash scripts/local-up.sh"
info "  Run tests         : bash scripts/local-test.sh"
info "  Deploy to AWS     : follow DEPLOY_STEPS.md"
