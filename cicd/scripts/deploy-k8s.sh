#!/usr/bin/env bash
# ============================================================================
# deploy-k8s.sh - deploy the application to the ACTIVE cloud's managed
# Kubernetes cluster (EKS | AKS | GKE) and smoke-test it. Shared by GitHub
# Actions (deploy.yml) and Jenkins (Jenkinsfile).
#
# Usage: bash cicd/scripts/deploy-k8s.sh <tag> <region> <env> <project> [cluster]
# Example: bash cicd/scripts/deploy-k8s.sh 1a2b3c4d ap-south-1 dev secure-ntier
#
# Cloud selection: CLOUD env var (aws | azure | gcp, default from stack.json).
#   kubeconfig: aws eks update-kubeconfig | az aks get-credentials |
#               gcloud container clusters get-credentials
#   DB secret : AWS Secrets Manager | Azure Key Vault | GCP Secret Manager
#               (materialized into the app-db-secret Kubernetes Secret)
# Requires: kubectl, jq, the active cloud's CLI + credentials.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

TAG="${1:?usage: deploy-k8s.sh <tag> <region> <env> <project> [cluster]}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-$("$INFO" project)}"

CLOUD="$("$INFO" cloud)"

case "$CLOUD" in
  aws)   DEFAULT_CLUSTER="${PROJECT}-${ENV_NAME}-eks" ;;
  azure) DEFAULT_CLUSTER="${PROJECT}-${ENV_NAME}-aks" ;;
  gcp)   DEFAULT_CLUSTER="${PROJECT}-${ENV_NAME}-gke" ;;
esac
CLUSTER="${5:-${K8S_CLUSTER:-$DEFAULT_CLUSTER}}"

REGISTRY="$(resolve_registry "$CLOUD" "$REGION")"
PUBLIC_SERVICE="$("$INFO" public-service)"

# --- 1. Connect to the cluster (kubeconfig per cloud) ------------------------
echo ">>> Configuring kubeconfig for ${CLUSTER} in ${REGION} (${CLOUD})"
case "$CLOUD" in
  aws)
    aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"
    ;;
  azure)
    RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-${PROJECT}-${ENV_NAME}-rg}"
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER" \
      --overwrite-existing
    ;;
  gcp)
    gcloud container clusters get-credentials "$CLUSTER" \
      --region "$REGION" ${GCP_PROJECT:+--project "$GCP_PROJECT"}
    ;;
esac

# --- 2. Materialize the DB credentials into a Kubernetes Secret ---------------
echo ">>> Reading DB credentials from the ${CLOUD} secret store"
SECRET_JSON=""
case "$CLOUD" in
  aws)
    SECRET_ID="${DB_SECRET_ID:-${PROJECT}-${ENV_NAME}-db-credentials}"
    SECRET_JSON="$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_ID" --region "$REGION" \
      --query SecretString --output text)"
    ;;
  azure)
    # db_secret_ref is the Key Vault secret ID:
    #   https://<vault>.vault.azure.net/secrets/<name>[/<version>]
    SECRET_REF="${DB_SECRET_REF:-$(terraform -chdir="$REPO_ROOT/terraform" output -raw db_secret_ref 2>/dev/null | tr -d '\r' || true)}"
    if [ -n "$SECRET_REF" ]; then
      KV_NAME="$(echo "$SECRET_REF" | sed -E 's#https://([^.]+)\..*#\1#')"
      KV_SECRET="$(echo "$SECRET_REF" | sed -E 's#.*/secrets/([^/]+).*#\1#')"
    else
      KV_NAME="${AZURE_KEY_VAULT:?set AZURE_KEY_VAULT or apply Terraform first}"
      KV_SECRET="${PROJECT}-${ENV_NAME}-db-credentials"
    fi
    SECRET_JSON="$(az keyvault secret show --vault-name "$KV_NAME" --name "$KV_SECRET" \
      --query value -o tsv)"
    ;;
  gcp)
    # db_secret_ref is the Secret Manager resource id:
    #   projects/<project>/secrets/<name>
    SECRET_REF="${DB_SECRET_REF:-$(terraform -chdir="$REPO_ROOT/terraform" output -raw db_secret_ref 2>/dev/null | tr -d '\r' || true)}"
    GCP_SECRET="${SECRET_REF##*/}"
    [ -n "$GCP_SECRET" ] || GCP_SECRET="${PROJECT}-${ENV_NAME}-db-credentials"
    SECRET_JSON="$(gcloud secrets versions access latest --secret="$GCP_SECRET" \
      ${GCP_PROJECT:+--project "$GCP_PROJECT"})"
    ;;
esac

kubectl create secret generic app-db-secret \
  --namespace secure-ntier \
  --from-literal=DB_HOST="$(echo "$SECRET_JSON" | jq -r .host)" \
  --from-literal=DB_PORT="$(echo "$SECRET_JSON" | jq -r .port)" \
  --from-literal=DB_NAME="$(echo "$SECRET_JSON" | jq -r .dbname)" \
  --from-literal=DB_USER="$(echo "$SECRET_JSON" | jq -r .username)" \
  --from-literal=DB_PASSWORD="$(echo "$SECRET_JSON" | jq -r .password)" \
  --from-literal=JWT_SECRET="$(echo "$SECRET_JSON" | jq -r .jwt_secret)" \
  --dry-run=client -o yaml | kubectl apply -f -

# --- 3. Apply manifests -------------------------------------------------------
# Static support (namespace + non-secret config) via kustomize; the per-service
# Deployment/Service/HPA/PDB manifests are RENDERED from stack.json so a new
# service needs no manifest edits.
echo ">>> Applying namespace + config (kustomize)"
kubectl apply -k "$REPO_ROOT/kubernetes"

echo ">>> Rendering per-service manifests from stack.json"
RENDERED="$(bash "$REPO_ROOT/kubernetes/scripts/render-manifests.sh" "$PROJECT" secure-ntier)"
echo "$RENDERED" | kubectl apply -f -

# --- 4. Point the deployments at the new images --------------------------------
for SVC in $("$INFO" list); do
  URI="${REGISTRY}/$(repo_path "$CLOUD" "$SVC" "$PROJECT" "$ENV_NAME"):${TAG}"
  echo ">>> Rolling ${SVC} -> ${URI}"
  kubectl -n secure-ntier set image "deployment/${SVC}" "${SVC}=${URI}"
done

# --- 5. Wait for the rollouts ---------------------------------------------------
for SVC in $("$INFO" list); do
  echo ">>> Waiting for ${SVC} rollout"
  kubectl -n secure-ntier rollout status "deployment/${SVC}" --timeout=300s
done

# --- 6. Smoke test the load balancer endpoint ----------------------------------
# EKS/NLB exposes .hostname; AKS/GKE L4/L7 LBs usually expose .ip.
ENDPOINT="$(kubectl -n secure-ntier get svc "$PUBLIC_SERVICE" \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

if [ -z "$ENDPOINT" ]; then
  echo ">>> No load balancer address yet - skipping smoke test (check 'kubectl get svc ${PUBLIC_SERVICE} -n secure-ntier')."
  exit 0
fi

echo ">>> Waiting for http://${ENDPOINT}/health to return 200 (up to 6 minutes)"
for i in $(seq 1 36); do
  if curl -sf "http://${ENDPOINT}/health" >/dev/null 2>&1; then
    echo ">>> ${CLOUD} k8s app is healthy at http://${ENDPOINT}/health"
    exit 0
  fi
  echo "    not ready yet (attempt $i/36), waiting 10s"
  sleep 10
done

echo "ERROR: app did not become healthy after 6 minutes" >&2
exit 1
