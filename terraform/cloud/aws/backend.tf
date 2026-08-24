# ============================================================================
# Remote state backend.
#
# The actual bucket/dynamodb values are supplied per environment with:
#   terraform init -backend-config="environments/<env>/backend.hcl"
#
# S3 keeps state remote (shared + encrypted) and DynamoDB provides state
# locking so two people cannot apply at the same time.
# ============================================================================

terraform {
  backend "s3" {}
}
