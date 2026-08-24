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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the ACR lives in"
  type        = string
}

variable "repositories" {
  description = "List of repository keys to expose URLs for (e.g. [\"backend\", \"frontend\"])"
  type        = list(string)
}
