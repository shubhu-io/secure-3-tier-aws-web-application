# ============================================================================
# Provider configuration (root)
#
# All three providers are configured HERE and passed into the matching cloud
# module via `providers = { ... }`. This is what makes the `count = 0`
# dispatcher pattern legal (a module that owns provider configs cannot be
# counted).
#
# Only the selected cloud's provider is ever *used*: the other two have zero
# resources in state, so no credentials are needed for them at plan/apply time.
#
# Credentials come from each CLI's standard chain:
#   aws    → aws configure / SSO / role assumption
#   azurerm→ az login / ARM_* environment variables
#   google → gcloud auth application-default login / GOOGLE_CREDENTIALS
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

provider "azurerm" {
  features {}
}

provider "google" {
  # Empty project falls back to GOOGLE_PROJECT / gcloud defaults; the GCP
  # implementation also threads var.project into every resource explicitly.
}
