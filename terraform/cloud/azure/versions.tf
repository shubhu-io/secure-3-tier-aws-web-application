# ============================================================================
# Terraform + provider version constraints (Azure implementation).
#
# Pinned here so the whole project builds with a known-good toolchain. The
# azurerm provider is configured in provider.tf; only the version lives here.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
