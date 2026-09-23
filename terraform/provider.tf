# ============================================================================
# Provider configuration (AWS)
#
# Credentials come from the AWS standard chain:
#   aws configure / SSO / IAM role / environment variables
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
