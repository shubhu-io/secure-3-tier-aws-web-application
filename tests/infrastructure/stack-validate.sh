#!/usr/bin/env bash
# ============================================================================
# stack-validate.sh - test the manifest-driven scripts WITHOUT AWS:
#   1. stack-validate.sh   -> the repo's stack.json passes its own validation
#   2. stack-info.sh       -> every query subcommand returns the expected values
#   3. negative test       -> a malformed manifest FAILS stack-validate
#
# Requires jq on PATH. Skips (warning) if jq is missing.
# ============================================================================
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

if ! command -v jq >/dev/null 2>&1; then
  echo "WARN: jq not found on PATH - skipping manifest script validation"
  exit 0
fi

FAIL=0
ok()  { echo "  [OK]   $*"; }
miss() { echo "  [MISS] $*"; FAIL=1; }

echo "===== 1. stack-validate.sh accepts the repo manifest ====="
if bash cicd/scripts/stack-validate.sh >/dev/null 2>&1; then
  ok "stack-validate.sh exits 0 on the repo stack.json"
else
  miss "stack-validate.sh rejected the repo stack.json"
fi

echo ""
echo "===== 2. stack-info.sh subcommands return the expected values ====="
EXPECT_PROJECT=$(bash cicd/scripts/stack-info.sh project)
[ "$EXPECT_PROJECT" = "secure-ntier" ] && ok "project = secure-ntier" || miss "project = $EXPECT_PROJECT"

LIST=$(bash cicd/scripts/stack-info.sh list | tr -d '\r')
[ "$LIST" = "$(printf 'backend\nfrontend')" ] && ok "list = backend, frontend" || miss "list: $(echo "$LIST" | tr '\n' ' ')"

COUNT=$(bash cicd/scripts/stack-info.sh count)
[ "$COUNT" = "2" ] && ok "count = 2" || miss "count = $COUNT"

PUBLIC=$(bash cicd/scripts/stack-info.sh public-service)
[ "$PUBLIC" = "frontend" ] && ok "public-service = frontend" || miss "public-service = $PUBLIC"

DB_ENGINE=$(bash cicd/scripts/stack-info.sh db-engine)
[ "$DB_ENGINE" = "mysql" ] && ok "db-engine = mysql" || miss "db-engine = $DB_ENGINE"

DB_PORT=$(bash cicd/scripts/stack-info.sh db-port)
[ "$DB_PORT" = "3306" ] && ok "db-port = 3306" || miss "db-port = $DB_PORT"

DB_VER=$(bash cicd/scripts/stack-info.sh db-version)
[ "$DB_VER" = "8.0" ] && ok "db-version = 8.0" || miss "db-version = $DB_VER"

PORT=$(bash cicd/scripts/stack-info.sh field backend port)
[ "$PORT" = "3000" ] && ok "backend port = 3000" || miss "backend port = $PORT"

STEPS=$(bash cicd/scripts/stack-info.sh ci-steps backend | head -1)
[ "$STEPS" = "npm ci" ] && ok "backend ci_steps[0] = npm ci" || miss "backend ci_steps[0] = $STEPS"

echo ""
echo "===== 3. negative tests: a bad manifest must be rejected ====="
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/bad-two-public.json" <<'EOF'
{
  "project": "secure-ntier",
  "services": [
    { "name": "backend", "port": 3000, "public": false, "source_dir": "application/backend", "dockerfile": "docker/backend/Dockerfile", "toolchain": "node:20-alpine", "ci_steps": [{ "name": "t", "command": "npm test" }] },
    { "name": "frontend", "port": 80, "public": true, "source_dir": "application/frontend", "dockerfile": "docker/frontend/Dockerfile", "toolchain": "node:20-alpine", "ci_steps": [{ "name": "b", "command": "npm run build" }] },
    { "name": "admin", "port": 8080, "public": true, "source_dir": "application/frontend", "dockerfile": "docker/frontend/Dockerfile", "toolchain": "node:20-alpine", "ci_steps": [{ "name": "b", "command": "npm run build" }] }
  ],
  "database": { "engine": "mysql", "engine_version": "8.0", "port": 3306 }
}
EOF

if STACK_FILE="$TMP_DIR/bad-two-public.json" bash cicd/scripts/stack-validate.sh >/dev/null 2>&1; then
  miss "accepted a manifest with two public services"
else
  ok "rejects two public services"
fi

cat > "$TMP_DIR/bad-missing-src.json" <<'EOF'
{
  "project": "secure-ntier",
  "services": [
    { "name": "backend", "port": 3000, "public": false, "source_dir": "does/not/exist", "dockerfile": "docker/backend/Dockerfile", "toolchain": "node:20-alpine", "ci_steps": [{ "name": "t", "command": "npm test" }] },
    { "name": "frontend", "port": 80, "public": true, "source_dir": "application/frontend", "dockerfile": "docker/frontend/Dockerfile", "toolchain": "node:20-alpine", "ci_steps": [{ "name": "b", "command": "npm run build" }] }
  ],
  "database": { "engine": "mysql", "engine_version": "8.0", "port": 3306 }
}
EOF

if STACK_FILE="$TMP_DIR/bad-missing-src.json" bash cicd/scripts/stack-validate.sh >/dev/null 2>&1; then
  miss "accepted a service with a missing source_dir"
else
  ok "rejects a missing source_dir"
fi

echo ""
if [ "$FAIL" = "1" ]; then
  echo "===== FAIL: manifest script tests ====="
  exit 1
fi
echo "===== PASS: all manifest script tests passed ====="
