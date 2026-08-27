#!/usr/bin/env bash
# ============================================================================
# Load test runner - k6 (preferred) or hey (fallback).
#
#   ./load-testing/run.sh https://my-alb.eu-west-1.elb.amazonaws.com smoke
#   ./load-testing/run.sh http://localhost stress
#
# Profiles:
#   smoke  - 1 VU, 30s  - deploy gate, expect p95 < 800ms, zero errors
#   stress - ramping to ~400 req/s over ~11min - exercises ASG scale-out
#            (watch the CPU>70 percent alarm + instance refresh kick in)
# ============================================================================
set -euo pipefail

BASE_URL="${1:?usage: run.sh <base-url> [smoke|stress]}"
PROFILE="${2:-smoke}"

if ! curl -sf "${BASE_URL}/health" >/dev/null; then
  echo "ERROR: ${BASE_URL}/health is not reachable - fix that first." >&2
  exit 1
fi

if command -v k6 >/dev/null 2>&1; then
  BASE_URL="${BASE_URL}" k6 run "$(dirname "$0")/${PROFILE}.js"
elif command -v hey >/dev/null 2>&1; then
  echo "k6 not found; running a quick hey burst instead of profile '${PROFILE}'."
  case "${PROFILE}" in
    smoke) hey -z 30s -c 1  "${BASE_URL}/api/items" ;;
    stress) hey -z 5m -c 50 "${BASE_URL}/api/items" ;;
    *) echo "unknown profile: ${PROFILE}" >&2; exit 1 ;;
  esac
else
  echo "Install k6 (https://k6.io) or hey (go install github.com/rakyll/hey@latest)." >&2
  exit 127
fi
