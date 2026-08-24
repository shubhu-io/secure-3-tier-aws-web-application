# ============================================================================
# Compute module variables
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
  description = "Resource group the VMSS lives in"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs (first one hosts the VMSS)"
  type        = list(string)
}

variable "app_nsg_id" {
  description = "Application NSG ID (kept for parity; the NSG is already associated to the subnet)"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID (scope for the AcrPull role assignment)"
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server (e.g. myacr.azurecr.io)"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID (scope for the Secrets User role assignment)"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name (the VMSS fetches the secret at boot)"
  type        = string
}

variable "db_secret_name" {
  description = "Key Vault secret name holding DB credentials"
  type        = string
}

variable "db_host" {
  description = "PostgreSQL server FQDN (kept for parity / future use)"
  type        = string
  sensitive   = true
}

variable "services" {
  description = "Application services from stack.json"
  type = list(object({
    name        = string
    language    = optional(string)
    port        = number
    public      = bool
    source_dir  = optional(string)
    dockerfile  = optional(string)
    toolchain   = optional(string)
    ci_steps    = optional(list(any))
    health_path = optional(string)
  }))
}

variable "vm_size" {
  description = "VM size for the scale set"
  type        = string
  default     = "Standard_B1s"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "zones" {
  description = "Availability zones to spread the VMSS across"
  type        = list(string)
  default     = ["1", "2"]
}

variable "health_check_path" {
  description = "Health check path (informational; App Gateway probe uses /health)"
  type        = string
  default     = "/health"
}

variable "appgw_backend_pool_ids" {
  description = "Application Gateway backend address pool IDs every VMSS NIC joins"
  type        = list(string)
  default     = []
}
