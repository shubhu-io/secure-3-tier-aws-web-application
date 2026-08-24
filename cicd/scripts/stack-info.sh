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
#   stack-info.sh clouds               -> supported clouds (one per line)
#   stack-info.sh cloud                -> ACTIVE cloud ($CLOUD or default_cloud)
#   stack-info.sh cloud-config         -> active cloud's config block (JSON)
#   stack-info.sh cloud-field <key>    -> region|registry|kubernetes of the
#                                         active cloud
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
    jq -r '.project' "$STACK_FILE" | tr -d '\r'
    ;;
  list)
    jq -r '.services[].name' "$STACK_FILE" | tr -d '\r'
    ;;
  count)
    jq -r '.services | length' "$STACK_FILE" | tr -d '\r'
    ;;
  public-service)
    jq -r '.services[] | select(.public == true) | .name' "$STACK_FILE" | tr -d '\r'
    ;;
  field)
    jq -r --arg svc "$1" --arg key "$2" \
      '.services[] | select(.name == $svc) | .[$key]' "$STACK_FILE" | tr -d '\r'
    ;;
  ci-steps)
    jq -r --arg svc "$1" \
      '.services[] | select(.name == $svc) | .ci_steps[].command' "$STACK_FILE" | tr -d '\r'
    ;;
  db-engine)
    jq -r '.database.engine' "$STACK_FILE" | tr -d '\r'
    ;;
  db-port)
    jq -r '.database.port' "$STACK_FILE" | tr -d '\r'
    ;;
  db-version)
    jq -r '.database.engine_version' "$STACK_FILE" | tr -d '\r'
    ;;
  clouds)
    jq -r '.clouds[]?' "$STACK_FILE" | tr -d '\r' | grep -v '^$' || true
    ;;
  cloud)
    DEFAULT_CLOUD="$(jq -r '.default_cloud // "aws"' "$STACK_FILE" | tr -d '\r')"
    ACTIVE_CLOUD="${CLOUD:-$DEFAULT_CLOUD}"
    # Validate against stack.json's "clouds" when the manifest declares them.
    if jq -e 'has("clouds")' "$STACK_FILE" >/dev/null; then
      jq -e --arg c "$ACTIVE_CLOUD" 'any(.clouds[]; . == $c)' "$STACK_FILE" >/dev/null || {
        echo "ERROR: CLOUD '$ACTIVE_CLOUD' is not one of stack.json clouds [$(jq -r '.clouds | join(", ")' "$STACK_FILE" | tr -d '\r')]" >&2
        exit 1
      }
    fi
    echo "$ACTIVE_CLOUD"
    ;;
  cloud-config)
    ACTIVE_CLOUD="$(bash "$SCRIPT_DIR/stack-info.sh" cloud)"
    jq --arg c "$ACTIVE_CLOUD" '.cloud_config[$c] // empty' "$STACK_FILE"
    ;;
  cloud-field)
    ACTIVE_CLOUD="$(bash "$SCRIPT_DIR/stack-info.sh" cloud)"
    jq -r --arg c "$ACTIVE_CLOUD" --arg key "$1" \
      '.cloud_config[$c][$key] // empty' "$STACK_FILE" | tr -d '\r'
    ;;
  *)
    echo "usage: stack-info.sh <path|project|list|count|public-service|field <svc> <key>|ci-steps <svc>|db-engine|db-port|db-version|clouds|cloud|cloud-config|cloud-field <key>>" >&2
    exit 2
    ;;
esac
