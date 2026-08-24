#!/bin/bash
# ============================================================================
# VMSS cloud-init (runs on first boot of every instance).
#
# 1. Install Docker + az CLI + jq
# 2. Authenticate to Azure with the instance's managed identity (no keys)
# 3. Log in to ACR using that identity
# 4. Read DB credentials from Key Vault (also via the managed identity)
# 5. For every service in stack.json: emit a docker-compose service using the
#    image <acr>/<name>:latest, then start the stack with retries so it
#    converges after the first apply (before the pipeline has pushed images).
#
# Single-brace placeholders are rendered by Terraform templatefile(); shell
# variables use $$VAR (escaped so Terraform leaves them intact).
# ============================================================================

set -euo pipefail

PROJECT="${project_name}"
ENVIRONMENT="${environment}"
ACR_LOGIN_SERVER="${acr_login_server}"
IDENTITY_CLIENT_ID="${identity_client_id}"
KEY_VAULT_NAME="${key_vault_name}"
DB_SECRET_NAME="${db_secret_name}"
SERVICES_JSON='${services_json}'

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "[$$(date -Is)] Starting cloud-init for $$PROJECT ($$ENVIRONMENT)"

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y ca-certificates curl jq docker.io

# Azure CLI (used for managed-identity login to ACR + Key Vault)
curl -sL https://aka.ms/InstallAzureCLIDeb | bash || true

systemctl enable --now docker
usermod -aG docker azureuser

# ---------------------------------------------------------------------------
# 2. Authenticate using the VM's user-assigned managed identity
# ---------------------------------------------------------------------------
az login --identity --username "$$IDENTITY_CLIENT_ID" >/dev/null
ACR_NAME="$${ACR_LOGIN_SERVER%%.azurecr.io}"
az acr login --name "$$ACR_NAME" --identity

# ---------------------------------------------------------------------------
# 3. DB credentials from Key Vault (managed identity)
# ---------------------------------------------------------------------------
DB_SECRET="$$(az keyvault secret show --vault-name "$$KEY_VAULT_NAME" --name "$$DB_SECRET_NAME" --query value -o tsv)"
DB_USER="$$(echo "$$DB_SECRET" | jq -r .username)"
DB_PASSWORD="$$(echo "$$DB_SECRET" | jq -r .password)"
DB_HOST="$$(echo "$$DB_SECRET" | jq -r .host)"
DB_PORT="$$(echo "$$DB_SECRET" | jq -r .port)"
DB_NAME="$$(echo "$$DB_SECRET" | jq -r .dbname)"
JWT_SECRET="$$(echo "$$DB_SECRET" | jq -r .jwt_secret)"

# ---------------------------------------------------------------------------
# 4. Emit docker-compose.yml - one service per stack.json service.
# ---------------------------------------------------------------------------
mkdir -p /opt/app
{
  echo "services:"
  echo "$${SERVICES_JSON}" | jq -c '.[]' | while read -r svc; do
    NAME="$$(echo "$$svc" | jq -r .name)"
    PORT="$$(echo "$$svc" | jq -r .port)"
    PUBLIC="$$(echo "$$svc" | jq -r .public)"
    IMAGE="$$ACR_LOGIN_SERVER/$$NAME:latest"

    echo "  $$NAME:"
    echo "    image: $$IMAGE"
    echo "    restart: unless-stopped"
    echo "    environment:"
    echo "      PORT: \"$$PORT\""
    echo "      NODE_ENV: \"production\""
    echo "      DB_HOST: \"$$DB_HOST\""
    echo "      DB_PORT: \"$$DB_PORT\""
    echo "      DB_NAME: \"$$DB_NAME\""
    echo "      DB_USER: \"$$DB_USER\""
    echo "      DB_PASSWORD: \"$$DB_PASSWORD\""
    echo "      JWT_SECRET: \"$$JWT_SECRET\""
    if [ "$$PUBLIC" = "true" ]; then
      echo "    ports:"
      echo "      - \"80:$$PORT\""
    fi
  done
} > /opt/app/docker-compose.yml

# ---------------------------------------------------------------------------
# 5. Start with retries (converges after first apply, before images pushed)
# ---------------------------------------------------------------------------
cd /opt/app
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  echo "[$$(date -Is)] compose up attempt $$attempt"
  if docker compose up -d 2>&1; then
    echo "[$$(date -Is)] stack is up"
    exit 0
  fi
  echo "[$$(date -Is)] stack not ready yet, waiting 30s"
  sleep 30
done

echo "[$$(date -Is)] ERROR: stack failed to start after 10 attempts"
exit 1
