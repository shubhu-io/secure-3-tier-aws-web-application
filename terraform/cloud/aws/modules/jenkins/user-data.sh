#!/bin/bash
# ============================================================================
# Jenkins controller user-data (cloud-init) - runs once on first boot.
#
# What it does:
#   1. Install Docker + compose plugin + jq
#   2. Build a Jenkins controller image (Jenkins LTS + AWS CLI v2 + kubectl
#      + Docker CLI) so the built-in node can run the pipeline stages
#   3. Run the controller container with:
#        - the host Docker socket (pipeline stages run `docker build`)
#        - the host docker group appended (socket permission)
#        - ports 8080 (UI) and 50000 (agent traffic)
#        - the instance role via IMDSv2 (no long-lived keys on the box)
#   4. Print the one-time admin password + URL to /var/log/jenkins-init.log
#
# After first boot, finish in the UI (see docs/deployment/jenkins.md):
#   - unlock with the initial admin password (read from the log above)
#   - give the built-in node labels "docker" and "linux"
#   - optionally add aws-access-key-id / aws-secret-access-key credentials;
#     without them the pipeline uses this instance role automatically
#
# Values marked {{ like this }} are rendered by Terraform templatefile().
# Runtime shell variables use $${VAR} (escaped so Terraform leaves them alone).
# ============================================================================

set -euo pipefail

REGION="{{ region }}"
ENVIRONMENT="{{ environment }}"
PROJECT_NAME="{{ project_name }}"
KUBECTL_VERSION="{{ kubectl_version }}"

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "[$$(date -Is)] Starting Jenkins user-data ($PROJECT_NAME-$ENVIRONMENT)"

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y ca-certificates curl jq docker.io docker-compose-v2

systemctl enable --now docker
usermod -aG docker ubuntu

# ---------------------------------------------------------------------------
# 2. Jenkins controller image
# ---------------------------------------------------------------------------
mkdir -p /opt/jenkins
cat > /opt/jenkins/Dockerfile <<'DOCKER_EOF'
FROM jenkins/jenkins:lts-jdk17
USER root
RUN apt-get update && apt-get install -y curl jq unzip \
    && rm -rf /var/lib/apt/lists/*
# AWS CLI v2 - the pipeline talks to AWS (ECR, SSM, ASG, EKS). Credentials
# come from the EC2 instance role via IMDSv2, so no keys are baked in.
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp/aws \
    && /tmp/aws/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws
# kubectl - only exercised when DEPLOY_EKS=true. Pinned to the EKS cluster.
ARG KUBECTL_VERSION
RUN curl -fsSL -o /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl
# Docker CLI - builds images through the host socket mounted at run time.
RUN curl -fsSL https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar -xz -C /tmp \
    && mv /tmp/docker/docker /usr/local/bin/docker
USER jenkins
DOCKER_EOF

docker build \
  --build-arg KUBECTL_VERSION="$${KUBECTL_VERSION}" \
  -t jenkins-controller:latest /opt/jenkins

# ---------------------------------------------------------------------------
# 3. Run the controller. The container reaches IMDSv2 (instance role) because
#    the launch config sets http_put_response_hop_limit = 2.
# ---------------------------------------------------------------------------
DOCKER_GID="$$(getent group docker | cut -d: -f3)"
docker rm -f jenkins 2>/dev/null || true
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/lib/jenkins:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$${DOCKER_GID}" \
  jenkins-controller:latest

# ---------------------------------------------------------------------------
# 4. Record the one-time admin password + next steps for the operator
# ---------------------------------------------------------------------------
for i in $$(seq 1 60); do
  [ -f /var/lib/jenkins/secrets/initialAdminPassword ] && break
  sleep 5
done

IMDS_TOKEN="$$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || true)"
PUBLIC_IP="$$(curl -fsS -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" \
  http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<pending>')"

{
  echo ""
  echo "================== JENKINS INITIAL SETUP =================="
  echo "URL: http://$${PUBLIC_IP}:8080/"
  echo ""
  echo "One-time initial admin password (from this box):"
  echo "--------------------------------------------------"
  cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null \
    || echo "still provisioning - run later: cat /var/lib/jenkins/secrets/initialAdminPassword"
  echo "--------------------------------------------------"
  echo "NEXT STEPS (docs/deployment/jenkins.md):"
  echo "  1. Open the URL, paste the password, install suggested plugins."
  echo "  2. Manage Jenkins -> Nodes -> built-in node: labels 'docker linux',"
  echo "     executors 2 (the pipeline needs a node labelled docker && linux)."
  echo "  3. (Optional) Add aws-access-key-id / aws-secret-access-key"
  echo "     credentials; without them the pipeline uses this instance role."
  echo "=========================================================="
} | tee /var/log/jenkins-init.log

echo "[$$(date -Is)] Jenkins user-data finished"
