# ============================================================================
# Terraform + provider version constraints.
#
# Pinned here (and mirrored in provider.tf for the aws/random providers) so
# the whole project builds with a known-good toolchain. Bumping the AWS
# provider major version requires re-running the full validation cycle.
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