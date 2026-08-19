#!/bin/bash
# ============================================================================
# EC2 user-data (cloud-init) - runs once on first boot.
#
# What it does:
#   1. Install Docker + compose plugin + jq
#   2. Authenticate to ECR using the INSTANCE ROLE (no keys on the machine)
#   3. Read DB credentials from AWS Secrets Manager
#   4. For every service in stack.json: read its image URI from SSM and emit
#      a docker-compose service (the `public` service maps to host port 80)
#   5. Start the stack with retries until healthy (lets the ASG converge
#      after first apply, before the pipeline has pushed the first images)
#
# Values marked {{ like this }} are rendered by Terraform templatefile().
# Runtime shell variables use $${VAR} (escaped so Terraform leaves them alone).
# ============================================================================

set -euo pipefail

REGION="{{ region }}"
ENVIRONMENT="{{ environment }}"
PROJECT="{{ project_name }}"
SECRET_NAME="{{ secret_name }}"
APP_NAME="{{ app_name }}"
SERVICES_JSON='{{ services_json }}'

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "[$$(date -Is)] Starting user-data for $APP_NAME ($ENVIRONMENT)"

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y ca-certificates curl jq docker.io docker-compose-v2

systemctl enable --now docker
usermod -aG docker ubuntu

# ---------------------------------------------------------------------------
# 2. ECR login using the instance role
# ---------------------------------------------------------------------------
ACCOUNT_ID="$$(aws sts get-caller-identity --region "$${REGION}" --query Account --output text)"
REGISTRY="$${ACCOUNT_ID}.dkr.ecr.$${REGION}.amazonaws.com"
aws ecr get-login-password --region "$${REGION}" | \
  docker login --username AWS --password-stdin "$${REGISTRY}"

# ---------------------------------------------------------------------------
# 3. DB credentials from Secrets Manager
# ---------------------------------------------------------------------------
DB_SECRET="$$(aws secretsmanager get-secret-value --secret-id "$${SECRET_NAME}" --region "$${REGION}" --query SecretString --output text)"

DB_USER="$$(echo "$${DB_SECRET}" | jq -r .username)"
DB_PASSWORD="$$(echo "$${DB_SECRET}" | jq -r .password)"
DB_HOST="$$(echo "$${DB_SECRET}" | jq -r .host)"
DB_PORT="$$(echo "$${DB_SECRET}" | jq -r .port)"
DB_NAME="$$(echo "$${DB_SECRET}" | jq -r .dbname)"
JWT_SECRET="$$(echo "$${DB_SECRET}" | jq -r .jwt_secret)"

# ---------------------------------------------------------------------------
# 4. Emit docker-compose.yml - one service per stack.json service.
#    Every service receives the platform env contract:
#    PORT, NODE_ENV, DB_* and JWT_SECRET. The public service maps to :80.
# ---------------------------------------------------------------------------
mkdir -p /opt/app
{
  echo "services:"
  echo "$${SERVICES_JSON}" | jq -c '.[]' | while read -r svc; do
    NAME="$$(echo "$${svc}" | jq -r .name)"
    PORT="$$(echo "$${svc}" | jq -r .port)"
    PUBLIC="$$(echo "$${svc}" | jq -r .public)"
    IMAGE="$$(aws ssm get-parameter --name "/$${PROJECT}/$${ENVIRONMENT}/$${NAME}-image" --region "$${REGION}" --query Parameter.Value --output text 2>/dev/null || echo '')"

    echo "  $${NAME}:"
    echo "    image: $${IMAGE}"
    echo "    restart: unless-stopped"
    echo "    environment:"
    echo "      PORT: \"$${PORT}\""
    echo "      NODE_ENV: \"production\""
    echo "      DB_HOST: \"$${DB_HOST}\""
    echo "      DB_PORT: \"$${DB_PORT}\""
    echo "      DB_NAME: \"$${DB_NAME}\""
    echo "      DB_USER: \"$${DB_USER}\""
    echo "      DB_PASSWORD: \"$${DB_PASSWORD}\""
    echo "      JWT_SECRET: \"$${JWT_SECRET}\""
    if [ "$${PUBLIC}" = "true" ]; then
      echo "    ports:"
      echo "      - \"80:$${PORT}\""
    fi
    echo "    logging:"
    echo "      driver: awslogs"
    echo "      options:"
    echo "        awslogs-group: \"/$${PROJECT}-$${ENVIRONMENT}/app\""
    echo "        awslogs-region: \"$${REGION}\""
    echo "        awslogs-stream-prefix: \"$${NAME}\""
  done
} > /opt/app/docker-compose.yml

# ---------------------------------------------------------------------------
# 5. Start the stack with retries (converges after the first terraform apply,
#    before the pipeline has pushed the first images to ECR).
# ---------------------------------------------------------------------------
cd /opt/app
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  echo "[$$(date -Is)] compose up attempt $attempt"
  if docker compose up -d --wait 2>&1; then
    echo "[$$(date -Is)] stack is up"
    exit 0
  fi
  echo "[$$(date -Is)] stack not ready yet, waiting 30s"
  sleep 30
done

echo "[$$(date -Is)] ERROR: stack failed to start after 10 attempts"
exit 1