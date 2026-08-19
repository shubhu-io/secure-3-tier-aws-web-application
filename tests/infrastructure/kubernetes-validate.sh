#!/usr/bin/env bash
# ============================================================================
# kubernetes-validate.sh - sanity-check the Kubernetes manifests without a
# cluster. Requires kubectl on PATH; skips (warning) if kubectl is missing.
#
#  1. kustomize build           -> always run (offline, validates static YAML)
#  2. render-manifests.sh       -> always run (generates per-service manifests
#                                  from stack.json and checks the output shape)
#  3. client dry-run            -> only when a cluster/context is reachable
# ============================================================================
set -uo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
  echo "WARN: kubectl not found on PATH - skipping Kubernetes manifest validation"
  exit 0
fi

echo "===== 1. kustomize build (static: namespace + config) ====="
kubectl kustomize kubernetes/ >/dev/null || { echo "FAIL: kustomize build failed"; exit 1; }
echo "OK - kustomize build succeeded"

echo ""
echo "===== 2. render per-service manifests from stack.json ====="
RENDERED="$(bash kubernetes/scripts/render-manifests.sh)" || {
  echo "FAIL: render-manifests.sh failed"; exit 1
}
KINDS="$(echo "$RENDERED" | grep -c '^kind:')"
echo "OK - rendered $KINDS resources (Deployment/Service/HPA/PDB per service)"
echo "$RENDERED" | grep -q "kind: Deployment" || { echo "FAIL: no Deployment rendered"; exit 1; }

echo ""
echo "===== 3. cluster reachability ====="
if kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
  echo "OK - cluster reachable"
  echo "===== 4. client-side dry-run apply ====="
  kubectl apply --dry-run=client -k kubernetes/ >/dev/null || {
    echo "FAIL: kustomize dry-run failed"; exit 1
  }
  echo "$RENDERED" | kubectl apply --dry-run=client -f - >/dev/null || {
    echo "FAIL: rendered manifests dry-run failed"; exit 1
  }
  echo "OK - manifests valid against the cluster"
else
  echo "WARN: no reachable cluster - skipping dry-run (steps 1-2 already validated the manifests)"
fi

echo ""
echo "===== Kubernetes manifests valid ====="