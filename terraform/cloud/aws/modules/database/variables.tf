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

variable "db_subnet_ids" {
  description = "Private DB subnet IDs"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Database security group ID"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class (db.t3.micro for dev)"
  type        = string
  default     = "db.t3.micro"
}

variable "engine" {
  description = "RDS engine: postgres | mysql | mariadb (from stack.json)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "RDS engine version (must be valid for engine)"
  type        = string
  default     = "16.4"
}

variable "port" {
  description = "Database port (5432 postgres, 3306 mysql/mariadb)"
  type        = number
  default     = 5432
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

variable "db_allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper limit for storage autoscaling (GiB). 0 disables autoscaling."
  type        = number
  default     = 50
}

variable "db_multi_az" {
  description = "Multi-AZ for production failover (costs 2x)"
  type        = bool
  default     = false
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
  description = "Skip creating a final snapshot on destroy (dev convenience, risky in prod)"
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups when the instance is deleted"
  type        = bool
  default     = false
}

variable "enhanced_monitoring_interval" {
  description = "RDS Enhanced Monitoring interval in seconds (0 = disabled, 60 = 1-min, 300 = 5-min). Adds a small per-hour cost."
  type        = number
  default     = 0
}
