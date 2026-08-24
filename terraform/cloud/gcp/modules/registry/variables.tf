# ============================================================================
# Registry module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "project" {
  description = "GCP project ID (used in the repository URL)"
  type        = string
}

variable "region" {
  description = "GCP region (Artifact Registry location + registry host)"
  type        = string
}

variable "repositories" {
  description = "List of repository keys to create (e.g. [\"backend\", \"frontend\"])"
  type        = list(string)
}
