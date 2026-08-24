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

variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_id" {
  description = "VPC network self_link for the private service connection"
  type        = string
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "app_user"
}

variable "db_tier" {
  description = "Cloud SQL tier (e.g. db-f1-micro)"
  type        = string
  default     = "db-f1-micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Protect the DB from accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Cloud SQL has no final-snapshot concept; kept for parity"
  type        = bool
  default     = true
}

variable "db_multi_az" {
  description = "Regional (multi-zone) Cloud SQL for production failover"
  type        = bool
  default     = false
}

variable "db_port" {
  description = "Database port (5432 for PostgreSQL)"
  type        = number
  default     = 5432
}
