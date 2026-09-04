# ============================================================================
# DEV remote state backend
# Usage: terraform init -backend-config="environments/dev/backend.hcl"
#
# Create these resources first (one-time, via AWS Console or AWS CLI):
#   1. S3 bucket (bucket already exists, versioning ON)
#   2. DynamoDB table "terraform-locks" with partition key "LockID" (String)
# ============================================================================

bucket         = "your-org-terraform-state"     # <YOUR_STATE_BUCKET>
key            = "secure-ntier/dev/terraform.tfstate"
region         = "ap-south-1"                    # <YOUR_REGION>
encrypt        = true
dynamodb_table = "terraform-locks"
