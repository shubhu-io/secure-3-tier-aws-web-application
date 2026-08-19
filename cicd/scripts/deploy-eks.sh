#!/usr/bin/env bash
# ============================================================================
# deploy-eks.sh - deploy the application to the EKS cluster and smoke-test it.
# Shared by GitHub Actions (deploy.yml) and Jenkins (Jenkinsfile).
#
# Usage: bash cicd/scripts/deploy-eks.sh <tag> <region> <env> <project> [cluster]
# Example: bash cicd/scripts/deploy-eks.sh 1a2b3c4d eu-west-1 dev secure-ntier
#
# Requires: AWS credentials (eks:DescribeCluster, secretsmanager:GetSecretValue,
#           ssm:GetParameter), kubectl, awscli, jq, docker.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"

TAG="${1:?usage: deploy-eks.sh <tag> <region> <env> <project> [cluster]}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-$("$INFO" project)}"
CLUSTER="${5:-${PROJECT}-${ENV_NAME}-eks}"

# --- Deploy (kubeconfig + secret materialization + apply + rollout) ----------
bash kubernetes/scripts/deploy.sh "$TAG" "$REGION" "$ENV_NAME" "$PROJECT" "$CLUSTER"

# --- Smoke test the NLB endpoint ---------------------------------------------
PUBLIC_SERVICE="$("$INFO" public-service)"
ENDPOINT="$(kubectl -n secure-ntier get svc "$PUBLIC_SERVICE" \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

if [ -z "$ENDPOINT" ]; then
  echo ">>> No load balancer hostname yet - skipping smoke test (check `kubectl get svc $PUBLIC_SERVICE -n secure-ntier`)."
  exit 0
fi

echo ">>> Waiting for https://${ENDPOINT}/health to return 200 (up to 6 minutes)"
for i in $(seq 1 36); do
  if curl -sf "http://${ENDPOINT}/health" >/dev/null 2>&1; then
    echo ">>> EKS app is healthy at http://${ENDPOINT}/health"
    exit 0
  fi
  echo "    not ready yet (attempt $i/36), waiting 10s"
  sleep 10
done

echo "ERROR: EKS app did not become healthy after 6 minutes" >&2
exit 1
