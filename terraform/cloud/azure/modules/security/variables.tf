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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the NSGs live in"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID (kept for parity / future use)"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs to associate the public NSG to"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Application subnet IDs to associate the app NSG to"
  type        = list(string)
}

variable "db_subnet_ids" {
  description = "Database subnet IDs to associate the db NSG to"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (App Gateway source)"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "Application subnet CIDRs (VMSS source)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "Database subnet CIDRs"
  type        = list(string)
}

variable "db_port" {
  description = "Database port (PostgreSQL 5432)"
  type        = number
  default     = 5432
}
