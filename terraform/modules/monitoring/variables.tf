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
  description = "Email address that receives alarm notifications (must confirm the SNS subscription)"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name to alarm on"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN (for dimension suffix)"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN (for dimension suffix)"
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier (for dimension)"
  type        = string
}

variable "db_allocated_storage_gb" {
  description = "RDS allocated storage in GiB (for the storage alarm)"
  type        = number
}

variable "cpu_high_threshold" {
  description = "CPU alarm threshold (%)"
  type        = number
  default     = 70
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx count alarm threshold (per 5 minutes)"
  type        = number
  default     = 10
}

variable "rds_cpu_threshold" {
  description = "RDS CPU alarm threshold (%)"
  type        = number
  default     = 80
}
