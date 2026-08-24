# ============================================================================
# Security module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "network_id" {
  description = "VPC network self_link the firewall rules apply to"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside the instances"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port (PostgreSQL default 5432)"
  type        = number
  default     = 5432
}

variable "app_subnet_cidrs" {
  description = "Application subnet CIDRs permitted to reach the database"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR used for the internal firewall rule"
  type        = string
  default     = "10.0.0.0/16"
}

variable "lb_health_check_ranges" {
  description = "GCP external LB / health-check source ranges"
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

variable "iap_source_range" {
  description = "IAP source range for browser-based SSH"
  type        = string
  default     = "35.235.240.0/20"
}

variable "db_ingress_source_tags" {
  description = "Extra network tags (e.g. GKE node tag) allowed to reach the database"
  type        = list(string)
  default     = []
}

variable "enable_ssh_iap" {
  description = "Allow IAP SSH to the application tier"
  type        = bool
  default     = true
}
