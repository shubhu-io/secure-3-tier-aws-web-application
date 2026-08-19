#!/usr/bin/env bash
# ============================================================================
# stack-info.sh - read the stack.json manifest (single source of truth for the
# tech stack: services, toolchains, database engine, runtimes).
#
# Usage:
#   stack-info.sh path                 -> absolute path of stack.json
#   stack-info.sh project              -> project name
#   stack-info.sh list                 -> service names (one per line)
#   stack-info.sh count                -> number of services
#   stack-info.sh public-service       -> the single public (web) service
#   stack-info.sh field <svc> <key>    -> any field of a service (raw)
#   stack-info.sh ci-steps <svc>       -> ci_step commands (one per line)
#   stack-info.sh db-engine            -> postgres | mysql | mariadb
#   stack-info.sh db-port              -> database port
#   stack-info.sh db-version           -> database engine version
#
# Requires: jq on PATH. STACK_FILE can be overridden (default: repo stack.json).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_FILE="${STACK_FILE:-$(cd "$SCRIPT_DIR/../.." && pwd)/stack.json}"

if [ ! -f "$STACK_FILE" ]; then
  echo "ERROR: stack.json not found at $STACK_FILE" >&2
  exit 1
fi

cmd="${1:?usage: stack-info.sh <command>}"
shift || true

case "$cmd" in
  path)
    echo "$STACK_FILE"
    ;;
  project)
    jq -r '.project' "$STACK_FILE"
    ;;
  list)
    jq -r '.services[].name' "$STACK_FILE"
    ;;
  count)
    jq -r '.services | length' "$STACK_FILE"
    ;;
  public-service)
    jq -r '.services[] | select(.public == true) | .name' "$STACK_FILE"
    ;;
  field)
    jq -r --arg svc "$1" --arg key "$2" \
      '.services[] | select(.name == $svc) | .[$key]' "$STACK_FILE"
    ;;
  ci-steps)
    jq -r --arg svc "$1" \
      '.services[] | select(.name == $svc) | .ci_steps[].command' "$STACK_FILE"
    ;;
  db-engine)
    jq -r '.database.engine' "$STACK_FILE"
    ;;
  db-port)
    jq -r '.database.port' "$STACK_FILE"
    ;;
  db-version)
    jq -r '.database.engine_version' "$STACK_FILE"
    ;;
  *)
    echo "usage: stack-info.sh <path|project|list|count|public-service|field <svc> <key>|ci-steps <svc>|db-engine|db-port|db-version>" >&2
    exit 2
    ;;
esac
