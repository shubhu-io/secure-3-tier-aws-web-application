# ============================================================================
# Jenkins module variables
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
  description = "Resource group the Jenkins VM lives in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID hosting the Jenkins VM"
  type        = string
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to reach the Jenkins UI (8080) and agent port (50000)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_username" {
  description = "Admin username for the Jenkins VM"
  type        = string
  default     = "jenkinsadmin"
}

variable "vm_size" {
  description = "VM size for the Jenkins controller"
  type        = string
  default     = "Standard_B2s"
}

variable "cicd_rg_scope" {
  description = "Resource group scope the Jenkins managed identity is granted Contributor on"
  type        = string
}
