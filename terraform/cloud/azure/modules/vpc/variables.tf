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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the network lives in"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet"
  type        = string
}

variable "azs" {
  description = "Availability zones (at least 2)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (one per AZ)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (one per AZ)"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways (1 for dev, 2 for production HA)"
  type        = number
  default     = 1
}
