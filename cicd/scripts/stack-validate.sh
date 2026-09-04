#!/usr/bin/env bash
# ============================================================================
# stack-validate.sh - validate the stack.json manifest.
#
# Checks:
#   - project is a non-empty string
#   - at least one service; names are unique, lowercase [a-z0-9-]
#   - each service has the required fields and its source_dir / dockerfile
#     actually exist in the repo
#   - exactly ONE service is public (the web entry point on port 80)
#   - each public service listens on a valid container port
#   - database.engine is supported (postgres | mysql | mariadb)
#
# Runs in CI and locally. Exit code 0 = manifest is valid.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STACK_FILE="${STACK_FILE:-$REPO_ROOT/stack.json}"
INFO="$SCRIPT_DIR/stack-info.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$STACK_FILE" ] || fail "stack.json not found at $STACK_FILE"

echo "===== 1. project ====="
jq -e '(.project | type) == "string" and .project != ""' "$STACK_FILE" >/dev/null \
  || fail "project must be a non-empty string"

echo "===== 2. services list ====="
jq -e '(.services | type) == "array" and (.services | length) >= 1' "$STACK_FILE" >/dev/null \
  || fail "services must be a non-empty array"

jq -e '([.services[].name] | length) == ([.services[].name] | unique | length)' "$STACK_FILE" >/dev/null \
  || fail "service names must be unique"

echo "===== 3. per-service shape ====="
COUNT=$("$INFO" count)
for (( i = 0; i < COUNT; i++ )); do
  NAME=$(jq -r ".services[$i].name" "$STACK_FILE" | tr -d '\r')
  [ -n "$NAME" ] || fail "service[$i].name is empty"
  echo "    - $NAME"

  jq -e --arg n "$NAME" '.services[] | select(.name == $n) | (.name | test("^[a-z0-9-]+$"))' "$STACK_FILE" >/dev/null \
    || fail "$NAME: name must match ^[a-z0-9-]+$"

  jq -e --arg n "$NAME" '.services[] | select(.name == $n) | ((.port | type) == "number" and .port > 0)' "$STACK_FILE" >/dev/null \
    || fail "$NAME: port must be a positive number"

  jq -e --arg n "$NAME" '.services[] | select(.name == $n) | ((.public | type) == "boolean")' "$STACK_FILE" >/dev/null \
    || fail "$NAME: public must be a boolean"

  jq -e --arg n "$NAME" '.services[] | select(.name == $n) | (.toolchain | type) == "string" and .toolchain != ""' "$STACK_FILE" >/dev/null \
    || fail "$NAME: toolchain must be a non-empty string (container image)"

  jq -e --arg n "$NAME" '.services[] | select(.name == $n) | ((.ci_steps | type) == "array" and (.ci_steps | length) >= 1)' "$STACK_FILE" >/dev/null \
    || fail "$NAME: ci_steps must be a non-empty array"

  SRC=$("$INFO" field "$NAME" source_dir)
  DF=$("$INFO" field "$NAME" dockerfile)
  [ -n "$SRC" ] && [ -d "$REPO_ROOT/$SRC" ] || fail "$NAME: source_dir '$SRC' does not exist in the repo"
  [ -n "$DF" ] && [ -f "$REPO_ROOT/$DF" ] || fail "$NAME: dockerfile '$DF' does not exist in the repo"
done

echo "===== 4. exactly one public service ====="
jq -e '[.services[] | select(.public == true)] | length == 1' "$STACK_FILE" >/dev/null \
  || fail "exactly one service must have public: true (the web entry point)"

echo "===== 5. database ====="
jq -e '(.database | type) == "object"' "$STACK_FILE" >/dev/null \
  || fail "database must be an object"

ENGINE=$("$INFO" db-engine)
case "$ENGINE" in
  postgres|mysql|mariadb) ;;
  *) fail "database.engine '$ENGINE' not supported (postgres | mysql | mariadb)" ;;
esac

jq -e '(.database.port | type) == "number" and .database.port > 0' "$STACK_FILE" >/dev/null \
  || fail "database.port must be a positive number"
jq -e '(.database.engine_version | type) == "string" and .database.engine_version != ""' "$STACK_FILE" >/dev/null \
  || fail "database.engine_version must be a non-empty string"

echo ""
echo "===== stack.json is valid ====="
