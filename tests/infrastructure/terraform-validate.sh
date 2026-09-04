#!/usr/bin/env bash
# ============================================================================
# Infrastructure test: terraform format + validation
# Usage: bash tests/infrastructure/terraform-validate.sh
# ============================================================================
set -euo pipefail

# Change to the repository root (two levels up from this script) and then into terraform
cd "$(dirname "$0")/../.." && cd terraform

# Resolve terraform binary on both Unix and Windows (Git Bash) PATHs
TF_BIN="${TERRAFORM_BIN:-}"
if [ -z "$TF_BIN" ]; then
  if command -v terraform >/dev/null 2>&1; then TF_BIN="terraform"
  elif command -v terraform.exe >/dev/null 2>&1; then TF_BIN="terraform.exe"
  elif [ -x "/c/terraform/terraform.exe" ]; then TF_BIN="/c/terraform/terraform.exe"
  elif [ -x "C:/terraform/terraform.exe" ]; then TF_BIN="C:/terraform/terraform.exe"
  else TF_BIN="terraform"; fi
fi

echo "==> terraform fmt check ($TF_BIN)"
"$TF_BIN" fmt -check -recursive

echo "==> terraform init (backend=false so we can validate without a state bucket)"
"$TF_BIN" init -backend=false -input=false >/dev/null

echo "==> terraform validate"
"$TF_BIN" validate

echo "==> PASS: Terraform configuration is valid"
