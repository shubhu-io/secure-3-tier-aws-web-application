# ============================================================================
# Remote state backend (S3 + DynamoDB).
#
# Bucket, table, and key are supplied per environment at init time:
#   terraform init -backend-config="environments/dev/backend.hcl"
#   terraform init -backend-config="environments/prod/backend.hcl"
# ============================================================================

terraform {
  backend "s3" {}
}
