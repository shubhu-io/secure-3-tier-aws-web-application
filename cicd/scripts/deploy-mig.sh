#!/usr/bin/env bash
# ============================================================================
# deploy-mig.sh - roll the GCP managed instance group onto the new images
# Usage: bash cicd/scripts/deploy-mig.sh <tag> <region> <env> <project>
#
# The instance template's startup script pulls "<region>-docker.pkg.dev/...":
# latest" at boot, so a deploy = clone the current template (same startup
# config) under a new name tagged with the image tag, then start a rolling
# update of the MIG onto that template.
#
# Requires: gcloud authenticated (and project set / GCP_PROJECT), jq,
#           terraform output (optional, for names).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO="$SCRIPT_DIR/stack-info.sh"
# shellcheck source=cloud-lib.sh
. "$SCRIPT_DIR/cloud-lib.sh"

TAG="${1:?usage: deploy-mig.sh <tag> <region> <env> <project>}"
REGION="${2:?region required}"
ENV_NAME="${3:-dev}"
PROJECT="${4:-$("$INFO" project)}"

GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null | tr -d '\r')}"
[ -n "$GCP_PROJECT" ] || { echo "ERROR: no GCP project - run 'gcloud config set project' or set GCP_PROJECT" >&2; exit 1; }

# MIG name + current template: Terraform's normalized asg_name output wins.
MIG_NAME=""
if command -v terraform >/dev/null 2>&1; then
  MIG_NAME="$(terraform -chdir="$REPO_ROOT/terraform" output -raw asg_name 2>/dev/null | tr -d '\r' || true)"
fi
[ -n "$MIG_NAME" ] || MIG_NAME="${PROJECT}-${ENV_NAME}-mig"

CURRENT_TEMPLATE="$(gcloud compute instance-groups managed describe "$MIG_NAME" \
  --region "$REGION" --project "$GCP_PROJECT" \
  --format='value(instanceTemplate)')"
[ -n "$CURRENT_TEMPLATE" ] || { echo "ERROR: MIG '$MIG_NAME' not found in ${REGION}" >&2; exit 1; }

echo ">>> Current template: ${CURRENT_TEMPLATE}"

# 1. New template = exact clone of the running one (startup config included),
#    named with the tag so every deploy gets a unique, traceable template.
NEW_TEMPLATE="${PROJECT}-${ENV_NAME}-tpl-${TAG}"
if gcloud compute instance-templates describe "$NEW_TEMPLATE" --project "$GCP_PROJECT" >/dev/null 2>&1; then
  echo ">>> Template ${NEW_TEMPLATE} already exists - reusing it"
else
  gcloud compute instance-templates create "$NEW_TEMPLATE" \
    --project "$GCP_PROJECT" \
    --source-instance-template="$CURRENT_TEMPLATE"
fi

echo ">>> New images now available as :latest in ${REGION}-docker.pkg.dev/${GCP_PROJECT}"

# 2. Rolling update onto the new template (one at a time keeps capacity up).
gcloud compute instance-groups managed rolling-action start-update "$MIG_NAME" \
  --region "$REGION" --project "$GCP_PROJECT" \
  --version="template=${NEW_TEMPLATE}" \
  --max-unavailable=1 --max-surge=1

echo ">>> Rolling update started on ${MIG_NAME} -> ${NEW_TEMPLATE}"
