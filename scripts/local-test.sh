#!/usr/bin/env bash
# ============================================================================
# local-test.sh - Comprehensive developer test suite for local dev stack.
#
# Runs:
#   1. Container status and health validation
#   2. Application unit tests (in Node container if local node is not present)
#   3. End-to-end API integration tests against the live stack
#
# Usage:
#   bash scripts/local-test.sh [base_url]
# Example:
#   bash scripts/local-test.sh http://localhost
# ============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${1:-http://localhost}"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

header()  { echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"; }
pass()    { echo -e "  ${GREEN}[PASS]${RESET} $1"; }
fail()    { echo -e "  ${RED}[FAIL]${RESET} $1"; TOTAL_FAIL=$((TOTAL_FAIL + 1)); }
info()    { echo -e "  ${CYAN}[INFO]${RESET} $1"; }

TOTAL_FAIL=0

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      secure-ntier  —  Developer Validation Suite         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 1. Unit Tests ─────────────────────────────────────────────────────────────
header "1. Backend Unit Tests"
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  info "Running unit tests using local Node.js..."
  if (cd "$REPO_ROOT/application/backend" && npm test); then
    pass "Backend unit tests passed."
  else
    fail "Backend unit tests failed."
  fi
elif command -v docker >/dev/null 2>&1; then
  info "Local Node not found; running unit tests inside ephemeral node:22 container..."
  if docker run --rm -v "${REPO_ROOT}/application/backend:/app" -w /app node:22-alpine sh -c "npm ci --silent && npm test"; then
    pass "Backend containerized unit tests passed."
  else
    fail "Backend containerized unit tests failed."
  fi
else
  fail "Neither Node.js nor Docker available to execute unit tests."
fi

# ── 2. Health & Endpoint Probe ────────────────────────────────────────────────
header "2. Stack Health Probe (${BASE_URL})"
if bash "$REPO_ROOT/scripts/health-check.sh" "$BASE_URL"; then
  pass "Health endpoint responding with status:ok and db:connected."
else
  fail "Health check failed at ${BASE_URL}/health."
fi

# ── 3. Application Integration Tests ──────────────────────────────────────────
header "3. End-to-End API Integration"
if bash "$REPO_ROOT/tests/application/integration.sh" "$BASE_URL"; then
  pass "End-to-end API integration tests completed successfully."
else
  fail "End-to-end API integration tests failed."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  🎉 ALL SUITES PASSED! Local stack is in pristine shape.${RESET}"
  echo "══════════════════════════════════════════════════════════"
  exit 0
else
  echo -e "${RED}${BOLD}  ❌ ${TOTAL_FAIL} SUITE(S) FAILED. Please review the errors above.${RESET}"
  echo "══════════════════════════════════════════════════════════"
  exit 1
fi
