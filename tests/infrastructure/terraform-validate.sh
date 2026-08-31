#!/usr/bin/env bash
# ============================================================================
# Infrastructure test: terraform format + validation
# Usage: bash tests/infrastructure/terraform-validate.sh
# ============================================================================
set -euo pipefail

# Change to the repository root (two levels up from this script) and then into terraform
cd "$(dirname "$0")/../.." && cd terraform

echo "==> terraform fmt check"
terraform fmt -check -recursive

echo "==> terraform init (backend=false so we can validate without a state bucket)"
terraform init -backend=false -input=false >/dev/null

echo "==> terraform validate"
terraform validate

echo "==> PASS: Terraform configuration is valid"
