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

variable "alb_4xx_threshold" {
  description = "ALB 4xx count alarm threshold (per 5 minutes)"
  type        = number
  default     = 100
}

variable "alb_response_time_threshold" {
  description = "ALB target response time alarm threshold (seconds)"
  type        = number
  default     = 2.0
}

variable "alb_request_count_threshold" {
  description = "ALB request count alarm threshold (per 5 minutes) - below this the app may be unreachable"
  type        = number
  default     = 1
}

variable "rds_cpu_threshold" {
  description = "RDS CPU alarm threshold (%)"
  type        = number
  default     = 80
}

variable "rds_connections_threshold" {
  description = "RDS connection count alarm threshold"
  type        = number
  default     = 50
}
