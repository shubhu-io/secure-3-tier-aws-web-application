#!/bin/bash
# ============================================================================
# Jenkins controller cloud-init (first boot).
# Installs Docker + az CLI + kubectl, then runs the Jenkins LTS controller in
# a container. The VM's managed identity (az login --identity) is used by the
# pipelines to deploy - no keys on disk.
#
# ${project_name} / ${environment} are rendered by Terraform templatefile().
# ============================================================================

set -euo pipefail

PROJECT="${project_name}"
ENVIRONMENT="${environment}"

exec > >(tee -a /var/log/jenkins-user-data.log) 2>&1
echo "[$$(date -Is)] Starting Jenkins cloud-init for $$PROJECT ($$ENVIRONMENT)"

apt-get update -y
apt-get install -y ca-certificates curl jq docker.io

curl -sL https://aka.ms/InstallAzureCLIDeb | bash || true

# kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

systemctl enable --now docker
usermod -aG docker "${admin_username}"

# Run the Jenkins LTS controller (docker sock mounted for builds).
docker run -d --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

echo "[$$(date -Is)] Jenkins controller started"
