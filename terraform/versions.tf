# ============================================================================
# AWS root — Terraform + provider version constraints.
#
# This root module deploys the secure N-tier platform on AWS.
# Provider version constraints are pinned here so the whole project builds
# with a known-good toolchain.
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
