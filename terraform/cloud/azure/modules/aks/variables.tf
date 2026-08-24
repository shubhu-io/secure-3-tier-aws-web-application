# ============================================================================
# AKS module variables
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
  description = "Resource group the cluster lives in"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs (node pool placement)"
  type        = list(string)
}

variable "db_subnet_ids" {
  description = "Database subnet IDs (kept for parity / future private DNS)"
  type        = list(string)
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for the nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane"
  type        = string
  default     = "1.31.0"
}

variable "ci_principal_id" {
  description = "Object ID of the CI/CD principal granted cluster access"
  type        = string
  default     = ""
}

variable "zones" {
  description = "Availability zones to spread nodes across"
  type        = list(string)
  default     = ["1", "2"]
}
