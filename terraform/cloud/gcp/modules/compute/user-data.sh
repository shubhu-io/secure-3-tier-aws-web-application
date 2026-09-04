#!/bin/bash
# ============================================================================
# Secure-ntier GCP compute bootstrap
# ----------------------------------------------------------------------------
# - Installs Docker (no SSH; IAP/browser-based admin only)
# - Authenticates to Artifact Registry using the VM SERVICE ACCOUNT token
#   (no embedded credentials)
# - Reads DB credentials from Secret Manager (VM SA has secretAccessor)
# - Runs the Cloud SQL Auth Proxy so the app reaches the DB on 127.0.0.1:5432
#   with no public DB exposure
# - Pulls each service image from Artifact Registry and runs it
#
# NOTE: every shell dollar sign is written as $$ so that Terraform's
# templatefile() does not treat $VAR as interpolation.
# ============================================================================
set -euo pipefail

PROJECT="{{.project}}"
REGION="{{.region}}"
SECRET_ID="{{.db_secret_ref}}"
APP_PORT="{{.app_port}}"
SERVICES_JSON='{{.services_json}}'
IMAGES_JSON='{{.image_repository_urls_json}}'

# --- base packages ----------------------------------------------------------
apt-get update -y
apt-get install -y docker.io docker-compose jq curl ca-certificates
systemctl enable --now docker

# --- Artifact Registry auth via the VM service account (no creds in code) ----
TOKEN=$$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata/computeMetadata/v1/instance/service-accounts/default/token | jq -r .access_token)
echo "$$TOKEN" | docker login -u oauth2accesstoken --password-stdin \
  "https://$$REGION-docker.pkg.dev"

# --- fetch DB credentials from Secret Manager -------------------------------
SECRET=$$(curl -s -H "Authorization: Bearer $$TOKEN" \
  "https://secretmanager.googleapis.com/v1/projects/$$PROJECT/secrets/$$SECRET_ID/versions/latest:access" \
  | jq -r .payload.data | base64 -d)

DB_PORT=$$(echo "$$SECRET" | jq -r .port)
DB_NAME=$$(echo "$$SECRET" | jq -r .dbname)
DB_USER=$$(echo "$$SECRET" | jq -r .username)
DB_PASS=$$(echo "$$SECRET" | jq -r .password)
DB_CONN=$$(echo "$$SECRET" | jq -r .connection_name)

# --- Cloud SQL Auth Proxy (DB reachable only via private IP + proxy) --------
PROXY_BIN=/usr/local/bin/cloud-sql-proxy
curl -sSL "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.linux.amd64" \
  -o "$$PROXY_BIN"
chmod +x "$$PROXY_BIN"
nohup "$$PROXY_BIN" --port "$$DB_PORT" --private-ip "$$DB_CONN" >/var/log/cloud-sql-proxy.log 2>&1 &

# --- run each service -------------------------------------------------------
echo "$$IMAGES_JSON" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read -r svc img; do
  PORT=$$(echo "$$SERVICES_JSON" | jq -r --arg s "$$svc" '.[] | select(.name==$$s) | .port')
  PUBLIC=$$(echo "$$SERVICES_JSON" | jq -r --arg s "$$svc" '.[] | select(.name==$$s) | .public')
  HOST_PORT="$$PORT"
  if [ "$$PUBLIC" = "true" ]; then HOST_PORT="$$APP_PORT"; fi

  docker run -d --restart unless-stopped --name "$$svc" \
    -p "$${HOST_PORT}:$${PORT}" \
    -e DB_HOST=127.0.0.1 \
    -e DB_PORT="$$DB_PORT" \
    -e DB_NAME="$$DB_NAME" \
    -e DB_USER="$$DB_USER" \
    -e DB_PASSWORD="$$DB_PASS" \
    "$$img":latest
done
