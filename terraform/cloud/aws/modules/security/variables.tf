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

variable "vpc_id" {
  description = "VPC ID the security groups belong to"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside the instances"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port (PostgreSQL default)"
  type        = number
  default     = 5432
}

variable "db_ingress_extra_sg_ids" {
  description = "Extra security groups allowed to reach the database (e.g. the EKS cluster security group)"
  type        = list(string)
  default     = []
}
