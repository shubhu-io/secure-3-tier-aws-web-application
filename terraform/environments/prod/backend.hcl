# ============================================================================
# PROD remote state backend
# Usage: terraform init -backend-config="environments/prod/backend.hcl"
# ============================================================================

bucket         = "your-org-terraform-state-prod"   # <YOUR_STATE_BUCKET>
key            = "secure-ntier/prod/terraform.tfstate"
region         = "eu-west-1"                       # <YOUR_REGION>
encrypt        = true
dynamodb_table = "terraform-locks"
