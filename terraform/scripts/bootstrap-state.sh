#!/usr/bin/env bash
# ============================================================================
# bootstrap-state.sh - create the Terraform remote-state backend (one-time).
#
# Creates:
#   1. An S3 bucket (versioning ON, public access blocked) for state storage
#   2. A DynamoDB table "terraform-locks" for state locking
#
# Usage:
#   bash terraform/scripts/bootstrap-state.sh <region> [bucket-name]
#
# Examples:
#   bash terraform/scripts/bootstrap-state.sh ap-south-1
#   bash terraform/scripts/bootstrap-state.sh ap-south-1 my-org-terraform-state
#
# Then point environments/{dev,prod}/backend.hcl at the created bucket.
# ============================================================================
set -euo pipefail

REGION="${1:?usage: bootstrap-state.sh <region> [bucket-name]}"
BUCKET="${2:-your-org-terraform-state}"
TABLE="terraform-locks"

# --- 1. S3 state bucket ------------------------------------------------------
echo ">>> Creating S3 bucket ${BUCKET} in ${REGION}"

if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
  echo "    Bucket ${BUCKET} already exists - skipping create"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

echo ">>> Enabling versioning on ${BUCKET}"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo ">>> Blocking public access on ${BUCKET}"
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- 2. DynamoDB lock table --------------------------------------------------
echo ">>> Creating DynamoDB table ${TABLE} in ${REGION}"

if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "    Table ${TABLE} already exists - skipping create"
else
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
fi

# --- 3. Verify ----------------------------------------------------------------
echo ""
echo ">>> Verification:"
aws dynamodb list-tables --region "$REGION" | grep -i "$TABLE" || true
aws s3 ls 2>/dev/null | grep -i "$BUCKET" || true

echo ""
echo ">>> Done. Update the bucket in environments/{dev,prod}/backend.hcl:"
echo "      bucket = \"${BUCKET}\""