#!/bin/bash
# ============================================================================
# EC2 user-data (cloud-init) - runs once on first boot.
#
# What it does:
#   1. Install Docker + compose plugin + jq + AWS CLI + SSM agent
#   2. Authenticate to ECR using the INSTANCE ROLE (no keys on the machine)
#   3. Read DB credentials from SSM Parameter Store (SecureString) (validated, fail fast)
#   4. For every service in stack.json: read its image URI from SSM and emit
#      a docker-compose service (the `public` service maps to host port 80,
#      DB secrets go to backend services only, frontend waits for backend).
#      Fails fast with the fix when images are not published yet.
#   5. Pull + start the stack with retries until healthy.
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
# 1. System packages (AWS CLI is NOT on the Canonical AMI - required below)
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y ca-certificates curl jq gnupg unzip
# Docker's official repo (Ubuntu's archive lacks docker-compose-plugin).
# Falls back to Ubuntu packages if the repo is unreachable.
install -m 0755 -d /etc/apt/keyrings
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
fi
apt-get install -y docker.io docker-compose-plugin awscli \
  || apt-get install -y docker.io docker-compose awscli
command -v aws >/dev/null || { echo "ERROR: aws CLI install failed"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose plugin install failed"; exit 1; }

systemctl enable --now docker
usermod -aG docker ubuntu || true

# SSM agent for Session Manager (no SSH) - best effort, Canonical AMI varies
if ! systemctl is-active --quiet snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null; then
  snap install amazon-ssm-agent --classic 2>/dev/null || apt-get install -y amazon-ssm-agent 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 2. ECR login using the instance role
# ---------------------------------------------------------------------------
ACCOUNT_ID="$$(aws sts get-caller-identity --region "$${REGION}" --query Account --output text)"
REGISTRY="$${ACCOUNT_ID}.dkr.ecr.$${REGION}.amazonaws.com"
aws ecr get-login-password --region "$${REGION}" | \
  docker login --username AWS --password-stdin "$${REGISTRY}"

# ---------------------------------------------------------------------------
# 3. DB credentials from SSM Parameter Store (SecureString, standard tier)
# ---------------------------------------------------------------------------
DB_SECRET="$$(aws ssm get-parameter --name "$${SECRET_NAME}" --with-decryption --region "$${REGION}" --query Parameter.Value --output text)"

for field in username password host port dbname jwt_secret; do
  val="$$(echo "$${DB_SECRET}" | jq -r --arg k "$${field}" '.[$k] // empty')"
  if [ -z "$${val}" ] || [ "$${val}" = "null" ]; then
    echo "ERROR: secret $${SECRET_NAME} missing required key '$${field}'" >&2
    exit 1
  fi
done

DB_USER="$$(echo "$${DB_SECRET}" | jq -r .username)"
DB_PASSWORD="$$(echo "$${DB_SECRET}" | jq -r .password)"
DB_HOST="$$(echo "$${DB_SECRET}" | jq -r .host)"
DB_PORT="$$(echo "$${DB_SECRET}" | jq -r .port)"
DB_NAME="$$(echo "$${DB_SECRET}" | jq -r .dbname)"
JWT_SECRET="$$(echo "$${DB_SECRET}" | jq -r .jwt_secret)"

# ---------------------------------------------------------------------------
# 4. Emit docker-compose.yml - one service per stack.json service.
#    Backend services receive the platform env contract:
#    PORT, NODE_ENV, DB_* and JWT_SECRET. The public service maps to :80
#    and waits for the backend. Frontend (nginx) needs no DB secrets.
# ---------------------------------------------------------------------------
mkdir -p /opt/app
BACKENDS="$$(echo "$${SERVICES_JSON}" | jq -r '.[] | select(.public != true) | .name')"
{
  echo "services:"
  echo "$${SERVICES_JSON}" | jq -c '.[]' | while read -r svc; do
    NAME="$$(echo "$${svc}" | jq -r .name)"
    PORT="$$(echo "$${svc}" | jq -r .port)"
    PUBLIC="$$(echo "$${svc}" | jq -r .public)"
    LANGUAGE="$$(echo "$${svc}" | jq -r .language)"
    IMAGE="$$(aws ssm get-parameter --name "/$${PROJECT}/$${ENVIRONMENT}/$${NAME}-image" --region "$${REGION}" --query Parameter.Value --output text 2>/dev/null || echo '')"

    if [ -z "$${IMAGE}" ] || [ "$${IMAGE}" = "null" ] || [ "$${IMAGE}" = "pending" ]; then
      echo "ERROR: no image published yet for service '$${NAME}' (SSM value: '$${IMAGE}'). Run the deploy pipeline first." >&2
      exit 1
    fi

    echo "  $${NAME}:"
    echo "    image: $${IMAGE}"
    echo "    restart: unless-stopped"
    if [ "$${LANGUAGE}" = "node" ] && [ "$${PUBLIC}" != "true" ]; then
      echo "    environment:"
      echo "      PORT: \"$${PORT}\""
      echo "      NODE_ENV: \"production\""
      echo "      DB_HOST: \"$${DB_HOST}\""
      echo "      DB_PORT: \"$${DB_PORT}\""
      echo "      DB_NAME: \"$${DB_NAME}\""
      echo "      DB_USER: \"$${DB_USER}\""
      echo "      DB_PASSWORD: \"$${DB_PASSWORD}\""
      echo "      JWT_SECRET: \"$${JWT_SECRET}\""
    fi
    if [ "$${PUBLIC}" = "true" ]; then
      echo "    ports:"
      echo "      - \"80:$${PORT}\""
      echo "    depends_on:"
      for dep in $${BACKENDS}; do
        echo "      $${dep}:"
        echo "        condition: service_started"
      done
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
# 5. Start the stack with retries (ECR/RDS flakes on first boot).
#    NOTE: images must already be published by the deploy pipeline -
#    section 4 fails fast with the exact fix when SSM still holds "pending".
# ---------------------------------------------------------------------------
cd /opt/app
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  echo "[$$(date -Is)] compose up attempt $${attempt}"
  docker compose pull 2>&1 || echo "[$$(date -Is)] pull had failures, continuing to up"
  if docker compose up -d --wait 2>&1; then
    echo "[$$(date -Is)] stack is up"
    docker ps --format 'table {{.Names}}\t{{.Status}}'
    exit 0
  fi
  echo "[$$(date -Is)] stack not ready yet, waiting 30s"
  sleep 30
done

echo "[$$(date -Is)] ERROR: stack failed to start after 10 attempts"
exit 1