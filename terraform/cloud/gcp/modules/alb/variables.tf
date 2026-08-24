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

variable "region" {
  description = "GCP region"
  type        = string
}

variable "app_port" {
  description = "Backend port the instances listen on"
  type        = number
  default     = 80
}

variable "instance_group" {
  description = "Instance group self_link to register as the LB backend"
  type        = string
}

variable "domain_name" {
  description = "Domain for the app (enables managed TLS + HTTPS). Empty = HTTP only."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Attach a Cloud Armor security policy to the backend service"
  type        = bool
  default     = true
}

variable "alb_deletion_protection" {
  description = "GCP has no direct LB deletion-protection; kept for parity"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "GCP LB access logs are exported via Logging; not wired here"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}
