#!/usr/bin/env bash
# ============================================================================
# stack-ci.sh - generic CI for every service in stack.json.
#
# For each service:
#   1. run its ci_steps inside the declared toolchain container (mounted read-
#      write over the service's source_dir)
#   2. docker build the service image from its declared Dockerfile
#   3. trivy scan the image (fails on CRITICAL/HIGH)
#
# No AWS is needed - nothing is pushed or deployed. The same loop runs from
# GitHub Actions (ci.yml), Jenkins (Jenkinsfile-ci) and locally.
#
# Usage: bash cicd/scripts/stack-ci.sh [project]
#   project defaults to stack.json's project (used for the local image tag).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"

PROJECT="${1:-$("$INFO" project)}"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

for SVC in $("$INFO" list); do
  echo ""
  echo "================ $SVC ================"

  DIR=$("$INFO" field "$SVC" source_dir)
  TOOLCHAIN=$("$INFO" field "$SVC" toolchain)
  DOCKERFILE=$("$INFO" field "$SVC" dockerfile)
  IMAGE="${PROJECT}-${SVC}:ci"

  echo ">>> ci_steps (toolchain: $TOOLCHAIN, dir: $DIR)"
  while IFS= read -r step; do
    [ -n "$step" ] || continue
    echo "    $step"
    docker run --rm \
      -v "${REPO_ROOT}:/workspace" \
      -w "/workspace/$DIR" \
      "$TOOLCHAIN" sh -c "$step"
  done < <("$INFO" ci-steps "$SVC")

  echo ">>> docker build -f $DOCKERFILE -t $IMAGE"
  docker build -f "$DOCKERFILE" -t "$IMAGE" "$REPO_ROOT"

  echo ">>> trivy scan $IMAGE"
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image \
      --ignore-unfixed --exit-code 1 --severity CRITICAL,HIGH "$IMAGE"

  echo ">>> $SVC OK"
done

echo ""
echo "===== stack-ci: all services passed ====="