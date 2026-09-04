#!/usr/bin/env bash
# ============================================================================
# deploy-to-ec2.sh  –  End-to-end AWS EC2 deployment for secure-ntier
#
# What it does (in order):
#   1. Preflight  – verify all required tools are installed
#   2. Bootstrap  – create S3 state bucket + DynamoDB lock table (idempotent)
#   3. Terraform  – init → plan → apply  (provisions VPC, ALB, ASG, RDS, ECR…)
#   4. Build      – docker build backend + frontend images
#   5. Push       – authenticate to ECR and push every service image
#   6. Deploy     – update SSM image pointers + start ASG rolling refresh
#   7. Smoke test – poll ALB /health until healthy or timeout
#
# Usage:
#   bash scripts/deploy-to-ec2.sh <region> [environment] [project]
#
# Examples:
#   bash scripts/deploy-to-ec2.sh eu-west-1
#   bash scripts/deploy-to-ec2.sh ap-south-1 dev secure-ntier
#
# Prerequisites (set before running):
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   # OR use a named profile:  export AWS_PROFILE=my-profile
#
#   Copy and fill in the tfvars:
#     cp terraform/environments/dev/terraform.tfvars.example \
#        terraform/environments/dev/terraform.tfvars
#
#   Optional – set STATE_BUCKET to control the S3 bucket name:
#     export STATE_BUCKET=my-org-terraform-state
# ============================================================================
set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}━━━ $* ${RESET}"; }

# ── arguments ─────────────────────────────────────────────────────────────────
REGION="${1:-${AWS_REGION:-eu-west-1}}"
ENV_NAME="${2:-dev}"
PROJECT="${3:-secure-ntier}"
STATE_BUCKET="${STATE_BUCKET:-${PROJECT}-${ENV_NAME}-tfstate}"
TAG="${DEPLOY_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo "latest")}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
TF_VARS="$TF_DIR/environments/${ENV_NAME}/terraform.tfvars"
TF_BACKEND_HCL="$TF_DIR/cloud/aws/backend.hcl"
CICD_SCRIPTS="$REPO_ROOT/cicd/scripts"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      secure-ntier  —  AWS EC2 End-to-End Deploy          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "Region:      $REGION"
info "Environment: $ENV_NAME"
info "Project:     $PROJECT"
info "Image tag:   $TAG"
info "State bucket: $STATE_BUCKET"

# ── Step 1: Preflight ─────────────────────────────────────────────────────────
step "Step 1/7 — Preflight checks"

check_tool() {
  if ! command -v "$1" &>/dev/null; then
    die "Required tool '$1' not found. Run: bash scripts/setup.sh"
  fi
  success "$1 found ($(command -v "$1"))"
}

check_tool aws
check_tool terraform
check_tool docker
check_tool jq

# Verify AWS credentials work
aws sts get-caller-identity --query 'Account' --output text \
  --region "$REGION" &>/dev/null \
  || die "AWS credentials not configured. Run: aws configure"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --region "$REGION")"
success "AWS auth OK — Account: $ACCOUNT_ID"

# Check tfvars exist
if [[ ! -f "$TF_VARS" ]]; then
  warn "terraform.tfvars not found at: $TF_VARS"
  warn "Copying example file — PLEASE EDIT IT before continuing."
  cp "${TF_VARS}.example" "$TF_VARS"
  die "Edit $TF_VARS then re-run this script."
fi
success "terraform.tfvars found"

# ── Step 2: Bootstrap state backend ───────────────────────────────────────────
step "Step 2/7 — Bootstrap Terraform state backend (idempotent)"

bash "$TF_DIR/scripts/bootstrap-state.sh" "$REGION" "$STATE_BUCKET"

# Patch the backend.hcl with the actual bucket name (sed idempotent)
sed -i.bak \
  "s|bucket = \".*\"|bucket = \"$STATE_BUCKET\"|g" \
  "$TF_BACKEND_HCL" 2>/dev/null || true
success "State backend ready: s3://$STATE_BUCKET"

# ── Step 3: Terraform init → plan → apply ─────────────────────────────────────
step "Step 3/7 — Terraform init, plan, apply"

cd "$TF_DIR"

info "terraform init…"
terraform init \
  -backend-config="cloud/aws/backend.hcl" \
  -backend-config="key=aws/${ENV_NAME}/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -input=false -reconfigure

info "terraform validate…"
terraform validate

info "terraform plan…"
terraform plan \
  -var="cloud=aws" \
  -var-file="environments/${ENV_NAME}/terraform.tfvars" \
  -out=tfplan \
  -input=false

info "terraform apply…"
terraform apply -input=false tfplan
rm -f tfplan

success "Infrastructure provisioned"

# Grab the ALB URL from outputs
ALB_URL="$(terraform output -raw app_url 2>/dev/null || echo '')"
info "ALB URL: ${ALB_URL:-<not yet available>}"

cd "$REPO_ROOT"

# ── Step 4: Build Docker images ───────────────────────────────────────────────
step "Step 4/7 — Build Docker images"

REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Build every service defined in stack.json
for svc in $(jq -r '.services[].name' stack.json); do
  DOCKERFILE="docker/${svc}/Dockerfile"
  if [[ ! -f "$DOCKERFILE" ]]; then
    warn "Dockerfile not found: $DOCKERFILE — skipping $svc"
    continue
  fi
  IMAGE="${REGISTRY}/${PROJECT}-${ENV_NAME}-${svc}:${TAG}"
  info "Building $svc → $IMAGE"
  docker build \
    -f "$DOCKERFILE" \
    -t "$IMAGE" \
    .
  success "Built $svc"
done

# ── Step 5: Push to ECR ───────────────────────────────────────────────────────
step "Step 5/7 — Push images to ECR"

info "Authenticating to ECR…"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

for svc in $(jq -r '.services[].name' stack.json); do
  IMAGE="${REGISTRY}/${PROJECT}-${ENV_NAME}-${svc}:${TAG}"
  if docker image inspect "$IMAGE" &>/dev/null; then
    info "Pushing $svc…"
    docker push "$IMAGE"
    success "Pushed $svc → $IMAGE"
  else
    warn "Image $IMAGE not found locally — skipping push for $svc"
  fi
done

# ── Step 6: Deploy (SSM update + ASG refresh) ─────────────────────────────────
step "Step 6/7 — Deploy: update SSM image pointers + trigger ASG rolling refresh"

bash "$CICD_SCRIPTS/deploy-ec2.sh" "$TAG" "$REGION" "$ENV_NAME" "$PROJECT"
success "ASG instance refresh started"

# ── Step 7: Smoke test ────────────────────────────────────────────────────────
step "Step 7/7 — Smoke test (waiting for healthy response)"

if [[ -z "$ALB_URL" ]]; then
  # Try to get it now that apply is done
  cd "$TF_DIR"
  ALB_URL="$(terraform output -raw app_url 2>/dev/null || echo '')"
  cd "$REPO_ROOT"
fi

if [[ -z "$ALB_URL" ]]; then
  warn "Could not determine ALB URL — skipping smoke test."
  warn "Get it with:  cd terraform && terraform output app_url"
else
  export ALB_URL
  export ATTEMPTS=36   # 36 × 10s = 6 min
  bash "$CICD_SCRIPTS/smoke-test.sh"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           ✅  Deployment complete!                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "App URL:   ${ALB_URL:-run 'cd terraform && terraform output app_url'}"
info "Health:    ${ALB_URL}/health"
info "Tear down: make tf-destroy   (or cd terraform && terraform destroy)"
