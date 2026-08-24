# ============================================================================
# VPC module variables
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC (informational; custom-mode network)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Zones to place subnets in (at least 2)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per zone)"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (one per zone)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (one per zone)"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of reserved NAT IPs (1 for dev, 2 for prod HA)"
  type        = number
  default     = 1
}
