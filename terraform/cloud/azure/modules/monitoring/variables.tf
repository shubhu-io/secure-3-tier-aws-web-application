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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the alerts live in"
  type        = string
}

variable "notification_email" {
  description = "Email address that receives alarm notifications"
  type        = string
}

variable "asg_id" {
  description = "VMSS resource ID to alarm on"
  type        = string
}

variable "lb_id" {
  description = "Application Gateway resource ID to alarm on"
  type        = string
}

variable "db_id" {
  description = "PostgreSQL server resource ID to alarm on"
  type        = string
}

variable "db_allocated_storage_gb" {
  description = "Allocated storage in GiB (kept for parity / future storage alarms)"
  type        = number
  default     = 20
}
