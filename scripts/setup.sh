#!/usr/bin/env bash
# ============================================================================
# setup.sh - verify all local prerequisites are installed
# ============================================================================
set -u

echo "==> Checking prerequisites..."

check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "  [OK]   %s (%s)\n" "$1" "$("$2" 2>/dev/null | head -n 1)"
  else
    printf "  [MISS] %s - please install it (see docs/deployment/prerequisites.md)\n" "$1"
  fi
}

check git "git --version"
check terraform "terraform version"
check docker "docker --version"
check node "node --version"
check npm "npm --version"
check aws "aws --version"
check curl "curl --version"
check jq "jq --version"

echo ""
echo "==> Done. Any [MISS] entries must be installed before continuing."
echo "==> Configure AWS credentials with: aws configure"
