# ============================================================================
# Remote state backend for the multi-cloud root.
#
# The actual bucket / DynamoDB / key values are supplied per cloud + environment
# with -backend-config (see cloud/<cloud>/backend.hcl). Using a separate key per
# cloud keeps the three providers' state fully isolated.
#
#   terraform init -backend-config="cloud/aws/backend.hcl"
#   terraform init -backend-config="cloud/azure/backend.hcl"
#   terraform init -backend-config="cloud/gcp/backend.hcl"
# ============================================================================

terraform {
  backend "s3" {}
}
