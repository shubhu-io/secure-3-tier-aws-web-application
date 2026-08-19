#!/usr/bin/env bash
# ============================================================================
# deploy.sh - deploy the application to a Kubernetes cluster (EKS or local).
#
# Two modes:
#
#   AWS EKS (default):
#     bash kubernetes/scripts/deploy.sh <tag> <region> <env> <project>
#       - writes kubeconfig via `aws eks update-kubeconfig`
#       - reads the DB credentials from AWS Secrets Manager and materializes
#         them into the app-db-secret Kubernetes Secret (never in Git)
#       - applies kubernetes/ and rolls the new images
#
#   Local (kind / minikube / k3d - no AWS):
#     AWS_CREDS_MODE=local bash kubernetes/scripts/deploy.sh <tag> <region> <env> <project>
#       - skips the kubeconfig + Secrets Manager steps; you must create the
#         app-db-secret yourself first (see secret.yaml.example)
#
# Requires: kubectl, and for AWS mode also awscli + jq + valid AWS credentials.
# ============================================================================
set -euo pipefail

TAG="${1:?usage: deploy.sh <tag> <region> <env> <project> [cluster] [secret-id]}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-secure-ntier}"
CLUSTER="${5:-${PROJECT}-${ENV_NAME}-eks}"
SECRET_ID="${6:-${PROJECT}-${ENV_NAME}-db-credentials}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST_DIR="$REPO_ROOT/kubernetes"
INFO="$REPO_ROOT/cicd/scripts/stack-info.sh"
AWS_MODE="${AWS_CREDS_MODE:-aws}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PUBLIC_SERVICE="$("$INFO" public-service)"

# --- 1. Connect to the cluster ----------------------------------------------
if [ "$AWS_MODE" = "aws" ]; then
  echo ">>> Configuring kubeconfig for ${CLUSTER} in ${REGION}"
  aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"
else
  echo ">>> AWS mode disabled - using current kubectl context (${CLUSTER})"
fi

# --- 2. Materialize the DB credentials into a Kubernetes Secret --------------
if [ "$AWS_MODE" = "aws" ]; then
  echo ">>> Reading DB credentials from Secrets Manager: ${SECRET_ID}"
  SECRET_JSON="$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" --region "$REGION" \
    --query SecretString --output text)"

  DB_HOST="$(echo "$SECRET_JSON" | jq -r .host)"
  DB_PORT="$(echo "$SECRET_JSON" | jq -r .port)"
  DB_NAME="$(echo "$SECRET_JSON" | jq -r .dbname)"
  DB_USER="$(echo "$SECRET_JSON" | jq -r .username)"
  DB_PASSWORD="$(echo "$SECRET_JSON" | jq -r .password)"
  JWT_SECRET="$(echo "$SECRET_JSON" | jq -r .jwt_secret)"

  kubectl create secret generic app-db-secret \
    --namespace secure-ntier \
    --from-literal=DB_HOST="$DB_HOST" \
    --from-literal=DB_PORT="$DB_PORT" \
    --from-literal=DB_NAME="$DB_NAME" \
    --from-literal=DB_USER="$DB_USER" \
    --from-literal=DB_PASSWORD="$DB_PASSWORD" \
    --from-literal=JWT_SECRET="$JWT_SECRET" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo ">>> Using the existing app-db-secret (local mode)"
fi

# --- 3. Apply manifests ------------------------------------------------------
# Static support (namespace + non-secret config) via kustomize; the per-service
# Deployment/Service/HPA/PDB manifests are RENDERED from stack.json so a new
# service needs no manifest edits (mirrors the EC2 compose generation).
echo ">>> Applying namespace + config (kustomize)"
kubectl apply -k "$MANIFEST_DIR"

echo ">>> Rendering per-service manifests from stack.json"
RENDERED="$("$SCRIPT_DIR/render-manifests.sh" "$PROJECT" secure-ntier)"
echo "$RENDERED" | kubectl apply -f -

# --- 4. Point the deployments at the new images (one per manifest service) ---
for SVC in $("$INFO" list); do
  URI="${REGISTRY}/${PROJECT}-${ENV_NAME}-${SVC}:${TAG}"
  echo ">>> Rolling ${SVC} -> ${URI}"
  kubectl -n secure-ntier set image "deployment/${SVC}" "${SVC}=${URI}"
done

# --- 5. Wait for the rollouts -------------------------------------------------
for SVC in $("$INFO" list); do
  echo ">>> Waiting for ${SVC} rollout"
  kubectl -n secure-ntier rollout status "deployment/${SVC}" --timeout=300s
done

# --- 6. Show the public endpoint --------------------------------------------
echo ""
echo ">>> Deployed. Public endpoint:"
kubectl -n secure-ntier get svc "$PUBLIC_SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo ">>> curl http://<endpoint>/health"
