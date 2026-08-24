# ============================================================================
# Monitoring module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "notification_email" {
  description = "Email address that receives alarm notifications"
  type        = string
}

variable "asg_name" {
  description = "Managed instance group name to alarm on"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}
