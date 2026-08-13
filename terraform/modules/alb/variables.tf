# ============================================================================
# ALB module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the load balancer"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

variable "app_port" {
  description = "Target group port (Nginx inside the instances listens on 80)"
  type        = number
  default     = 80
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Leave empty for plain HTTP (dev only)."
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "ELB security policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Store ALB access logs in S3"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "health_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Consecutive successes before target is healthy"
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Consecutive failures before target is unhealthy"
  type        = number
  default     = 3
}

variable "enable_waf" {
  description = "Attach an AWS WAF web ACL to the ALB"
  type        = bool
  default     = true
}
