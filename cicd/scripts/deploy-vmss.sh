#!/usr/bin/env bash
# ============================================================================
# deploy-vmss.sh - point the Azure VM Scale Set at the new images and roll it
# Usage: bash cicd/scripts/deploy-vmss.sh <tag> <region> <env> <project>
#
# The VMSS custom-data (cloud-init) pulls "<acr>/<service>:latest" at boot, so
# a deploy = record the new image refs on the scale set model, then trigger a
# rolling upgrade so every instance reboots into the fresh images. With
# upgradePolicy=Automatic (the Terraform default) the model update kicks the
# rollout off on its own; with Manual we start it explicitly.
#
# Requires: az CLI logged in, jq, terraform output (optional, for names).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

TAG="${1:?usage: deploy-vmss.sh <tag> <region> <env> <project>}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-$("$INFO" project)}"

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-${PROJECT}-${ENV_NAME}-rg}"

# Scale set name: Terraform's normalized asg_name output wins, else convention.
VMSS_NAME=""
if command -v terraform >/dev/null 2>&1; then
  VMSS_NAME="$(terraform -chdir="$REPO_ROOT/terraform" output -raw asg_name 2>/dev/null | tr -d '\r' || true)"
fi
[ -n "$VMSS_NAME" ] || VMSS_NAME="${PROJECT}-${ENV_NAME}-vmss"

REGISTRY="$(resolve_registry azure "$REGION")"

az vmss show --resource-group "$RESOURCE_GROUP" --name "$VMSS_NAME" >/dev/null

# 1. Record each service's new image ref on the scale set model.
for svc in $("$INFO" list); do
  IMAGE="${REGISTRY}/$(repo_path azure "$svc" "$PROJECT" "$ENV_NAME"):${TAG}"

  az vmss update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VMSS_NAME" \
    --set "tags.${svc}-image=${IMAGE}" >/dev/null

  echo ">>> tags.${svc}-image = ${IMAGE}"
done

# 2. Rolling upgrade so every instance reboots into the new images.
#    Explicit start works in both upgrade modes; if one is already in flight
#    (Automatic mode may have kicked one off) we leave it running.
UPGRADE_MODE="$(az vmss show --resource-group "$RESOURCE_GROUP" --name "$VMSS_NAME" \
  --query 'upgradePolicy.mode' -o tsv | tr -d '\r')"

if az vmss rolling-upgrade start \
    --resource-group "$RESOURCE_GROUP" \
    --vm-scale-set-name "$VMSS_NAME" >/dev/null 2>&1
then
  echo ">>> Rolling upgrade started on ${VMSS_NAME} (upgradePolicy=${UPGRADE_MODE})"
else
  echo ">>> Rolling upgrade already in progress on ${VMSS_NAME} - leaving it in flight"
fi
