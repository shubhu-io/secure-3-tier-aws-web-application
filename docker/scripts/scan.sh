#!/usr/bin/env bash
# ============================================================================
# scan.sh - scan the locally built images with Trivy (CRITICAL/HIGH => fail).
#
#   bash docker/scripts/scan.sh
#
# Runs Trivy in a throwaway container, so it needs a Linux Docker socket
# (/var/run/docker.sock). On Windows/macOS there is no such socket, so the
# scan is skipped with a warning - install Trivy locally to scan instead:
#   trivy image secure-ntier-local-backend:latest
# ============================================================================
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_docker
load_env

if [[ ! -S /var/run/docker.sock ]]; then
  warn "No Linux Docker socket (/var/run/docker.sock) - skipping Trivy scan."
  warn "Install Trivy and run: trivy image secure-ntier-local-backend:latest"
  exit 0
fi

info "Building images (so they can be scanned)..."
docker compose -f "$COMPOSE_FILE" build

info "Scanning images with Trivy (fails on CRITICAL/HIGH)..."
FAILED=0
while IFS= read -r IMG; do
  [[ -n "$IMG" ]] || continue
  info "Scanning $IMG"
  if docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$HOME/.cache/trivy:/root/.cache" \
    aquasec/trivy:latest image --exit-code 1 --severity CRITICAL,HIGH --ignore-unfixed "$IMG"; then
    success "$IMG clean"
  else
    warn "$IMG has findings (CRITICAL/HIGH)"
    FAILED=1
  fi
done < <(docker compose -f "$COMPOSE_FILE" images --format "{{.Repository}}:{{.Tag}}")

if [[ $FAILED -eq 1 ]]; then
  die "Trivy found CRITICAL/HIGH findings - resolve them before pushing."
fi
success "All images passed the Trivy scan."