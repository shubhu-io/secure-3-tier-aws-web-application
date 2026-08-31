# ============================================================================
# Provider requirements — provider configuration lives in the ROOT
# terraform/provider.tf and is passed into this child via
#   providers = { aws = aws }
# Removing the local provider block allows the root's count dispatch
# (module "aws" count = var.cloud == "aws" ? 1 : 0) to be legal.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
