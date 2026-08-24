#!/usr/bin/env bash
# ============================================================================
# stack-validate.sh - test the manifest-driven scripts WITHOUT a cluster:
#   1. stack-validate.sh   -> the repo's stack.json passes its own validation
#   2. stack-info.sh       -> every query subcommand returns the expected values
#   3. render-manifests.sh -> per-service k8s output has the right shape
#   4. negative test       -> a malformed manifest FAILS stack-validate
#
# Requires jq on PATH. Skips (warning) if jq is missing, matching the
# kubernetes-validate.sh convention for optional tooling.
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
[ "$DB_ENGINE" = "postgres" ] && ok "db-engine = postgres" || miss "db-engine = $DB_ENGINE"

DB_PORT=$(bash cicd/scripts/stack-info.sh db-port)
[ "$DB_PORT" = "5432" ] && ok "db-port = 5432" || miss "db-port = $DB_PORT"

DB_VER=$(bash cicd/scripts/stack-info.sh db-version)
[ "$DB_VER" = "16.4" ] && ok "db-version = 16.4" || miss "db-version = $DB_VER"

PORT=$(bash cicd/scripts/stack-info.sh field backend port)
[ "$PORT" = "3000" ] && ok "backend port = 3000" || miss "backend port = $PORT"

STEPS=$(bash cicd/scripts/stack-info.sh ci-steps backend | head -1)
[ "$STEPS" = "npm ci" ] && ok "backend ci_steps[0] = npm ci" || miss "backend ci_steps[0] = $STEPS"

echo ""
echo "===== 3. render-manifests.sh output shape ====="
RENDERED="$(bash kubernetes/scripts/render-manifests.sh 2>/dev/null)"
RC=$?
[ "$RC" = "0" ] && ok "render-manifests.sh exits 0" || miss "render-manifests.sh exit = $RC"

KIND_COUNT=$(printf '%s\n' "$RENDERED" | grep -c '^kind:')
[ "$KIND_COUNT" = "8" ] && ok "8 rendered resources (2 services x 4 kinds)" || miss "rendered $KIND_COUNT resources, expected 8"

for kind in Deployment Service HorizontalPodAutoscaler PodDisruptionBudget; do
  N=$(printf '%s\n' "$RENDERED" | grep -c "^kind: $kind")
  [ "$N" = "2" ] && ok "2 x $kind" || miss "$kind count = $N, expected 2"
done

LB_COUNT=$(printf '%s\n' "$RENDERED" | grep -c 'type: LoadBalancer')
[ "$LB_COUNT" = "1" ] && ok "exactly 1 public LoadBalancer (frontend)" || miss "LoadBalancer count = $LB_COUNT, expected 1"

FSGROUP_LINES=$(printf '%s\n' "$RENDERED" | grep -c 'fsGroup: 10001')
[ "$FSGROUP_LINES" = "1" ] && ok "fsGroup 10001 on exactly the internal service (backend)" || miss "fsGroup lines = $FSGROUP_LINES, expected 1"

printf '%s\n' "$RENDERED" | grep -q 'maxReplicas: 6' && ok "HPA maxReplicas = 6" || miss "missing maxReplicas: 6"
printf '%s\n' "$RENDERED" | grep -q 'averageUtilization: 70' && ok "HPA CPU target = 70%" || miss "missing averageUtilization: 70"
printf '%s\n' "$RENDERED" | grep -q 'minAvailable: 1' && ok "PDB minAvailable = 1" || miss "missing minAvailable: 1"
printf '%s\n' "$RENDERED" | grep -q 'image: secure-ntier/backend:latest' && ok "backend image placeholder" || miss "missing backend image"
printf '%s\n' "$RENDERED" | grep -q 'image: secure-ntier/frontend:latest' && ok "frontend image placeholder" || miss "missing frontend image"

echo ""
echo "===== 4. negative tests: a bad manifest must be rejected ====="
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
  "database": { "engine": "postgres", "engine_version": "16.4", "port": 5432 }
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
  "database": { "engine": "postgres", "engine_version": "16.4", "port": 5432 }
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