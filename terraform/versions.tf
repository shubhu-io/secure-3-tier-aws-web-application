# ============================================================================
# Multi-cloud root - Terraform + provider version constraints.
#
# This root module is a thin dispatcher: it selects ONE cloud implementation
# (AWS, Azure or GCP) based on the `cloud` variable and instantiates the
# matching child module under ./cloud/<cloud>. Each cloud module is fully
# self-contained (it owns its own provider configuration + reads stack.json).
#
# Version constraints for the three providers are pinned here so the whole
# project builds with a known-good toolchain.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
