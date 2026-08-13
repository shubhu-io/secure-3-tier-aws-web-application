#!/bin/bash
# ============================================================================
# EC2 user-data (cloud-init) - runs once on first boot.
#
# What it does:
#   1. Install Docker + compose plugin + jq
#   2. Authenticate to ECR using the INSTANCE ROLE (no keys on the machine)
#   3. Read the latest image URIs from SSM Parameter Store
#   4. Read DB credentials from AWS Secrets Manager
#   5. Write docker-compose.yml and start the stack
#   6. Retry until healthy (lets the ASG converge after first apply)
#
# Values marked {{ like this }} are rendered by Terraform templatefile().
# Runtime shell variables use $${VAR} (escaped so Terraform leaves them alone).
# ============================================================================

set -euo pipefail

REGION="{{ region }}"
ENVIRONMENT="{{ environment }}"
SECRET_NAME="{{ secret_name }}"
BACKEND_PARAM="{{ backend_image_param }}"
FRONTEND_PARAM="{{ frontend_image_param }}"
APP_NAME="{{ app_name }}"

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "[$(date -Is)] Starting user-data for $APP_NAME ($ENVIRONMENT)"

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
# 3. Latest image URIs from SSM
# ---------------------------------------------------------------------------
BACKEND_IMAGE="$$(aws ssm get-parameter --name "$${BACKEND_PARAM}" --region "$${REGION}" --query Parameter.Value --output text 2>/dev/null || echo '')"
FRONTEND_IMAGE="$$(aws ssm get-parameter --name "$${FRONTEND_PARAM}" --region "$${REGION}" --query Parameter.Value --output text 2>/dev/null || echo '')"

# ---------------------------------------------------------------------------
# 4. DB credentials from Secrets Manager
# ---------------------------------------------------------------------------
DB_SECRET="$$(aws secretsmanager get-secret-value --secret-id "$${SECRET_NAME}" --region "$${REGION}" --query SecretString --output text)"

DB_USER="$$(echo "$${DB_SECRET}" | jq -r .username)"
DB_PASSWORD="$$(echo "$${DB_SECRET}" | jq -r .password)"
DB_HOST="$$(echo "$${DB_SECRET}" | jq -r .host)"
DB_PORT="$$(echo "$${DB_SECRET}" | jq -r .port)"
DB_NAME="$$(echo "$${DB_SECRET}" | jq -r .dbname)"
JWT_SECRET="$$(echo "$${DB_SECRET}" | jq -r .jwt_secret)"

# ---------------------------------------------------------------------------
# 5. Write docker-compose.yml
# ---------------------------------------------------------------------------
mkdir -p /opt/app
cat > /opt/app/docker-compose.yml <<'COMPOSE_EOF'
services:
  backend:
    image: REPLACE_BACKEND
    restart: unless-stopped
    environment:
      PORT: "3000"
      NODE_ENV: "production"
      DB_HOST: "REPLACE_HOST"
      DB_PORT: "REPLACE_PORT"
      DB_NAME: "REPLACE_NAME"
      DB_USER: "REPLACE_USER"
      DB_PASSWORD: "REPLACE_PASS"
      JWT_SECRET: "REPLACE_JWT"
    logging:
      driver: awslogs
      options:
        awslogs-group: "REPLACE_LOGGROUP"
        awslogs-region: "REPLACE_REGION"
        awslogs-stream-prefix: "backend"
  frontend:
    image: REPLACE_FRONTEND
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
    logging:
      driver: awslogs
      options:
        awslogs-group: "REPLACE_LOGGROUP"
        awslogs-region: "REPLACE_REGION"
        awslogs-stream-prefix: "frontend"
COMPOSE_EOF

# Substitute runtime values. The password never contains a single quote
# (it is generated with override_special that excludes "'"), so sed is safe.
sed -i \
  -e "s|REPLACE_BACKEND|$${BACKEND_IMAGE}|g" \
  -e "s|REPLACE_FRONTEND|$${FRONTEND_IMAGE}|g" \
  -e "s|REPLACE_HOST|$${DB_HOST}|g" \
  -e "s|REPLACE_PORT|$${DB_PORT}|g" \
  -e "s|REPLACE_NAME|$${DB_NAME}|g" \
  -e "s|REPLACE_USER|$${DB_USER}|g" \
  -e "s|REPLACE_PASS|$${DB_PASSWORD}|g" \
  -e "s|REPLACE_JWT|$${JWT_SECRET}|g" \
  -e "s|REPLACE_REGION|$${REGION}|g" \
  -e "s|REPLACE_LOGGROUP|/secure-ntier-$${ENVIRONMENT}/app|g" \
  /opt/app/docker-compose.yml

# ---------------------------------------------------------------------------
# 6. Start the stack with retries (converges after the first terraform apply,
#    before the pipeline has pushed the first images to ECR).
# ---------------------------------------------------------------------------
cd /opt/app
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  echo "[$(date -Is)] compose up attempt $attempt"
  if docker compose up -d --wait 2>&1; then
    echo "[$(date -Is)] stack is up"
    exit 0
  fi
  echo "[$(date -Is)] stack not ready yet, waiting 30s"
  sleep 30
done

echo "[$(date -Is)] ERROR: stack failed to start after 10 attempts"
exit 1
