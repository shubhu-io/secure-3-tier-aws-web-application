# ============================================================================
# Database module variables
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
  description = "Resource group the database lives in"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID (for the private DNS link)"
  type        = string
}

variable "db_subnet_id" {
  description = "Delegated DB subnet ID (first DB subnet)"
  type        = string
}

variable "db_sku" {
  description = "PostgreSQL Flexible Server SKU name (e.g. B_Standard_B1ms)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "pg_version" {
  description = "PostgreSQL major version (e.g. 16)"
  type        = string
  default     = "16"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Administrator login"
  type        = string
  default     = "app_user"
}

variable "db_allocated_storage_gb" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Zone-redundant PostgreSQL"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protect the DB from accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Mirrors the multi-cloud contract; flexible server has no final snapshot concept (kept for parity)"
  type        = bool
  default     = true
}
