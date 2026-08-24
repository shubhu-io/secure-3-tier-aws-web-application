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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the gateway lives in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID hosting the Application Gateway (must be a dedicated subnet)"
  type        = string
}

variable "appgw_nsg_id" {
  description = "Public NSG ID associated to the gateway subnet"
  type        = string
}

# The VMSS joins the backend pool itself (application_gateway_backend_address_pool_ids
# on its ip_configuration), so no NIC/IP plumbing is needed here.

variable "tenant_id" {
  description = "Azure tenant id (for the Key Vault access policies)"
  type        = string
}

variable "deployer_object_id" {
  description = "Object id of the principal running Terraform (to create the TLS cert)"
  type        = string
}

variable "enable_waf" {
  description = "Attach a WAF policy to the Application Gateway"
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Store gateway access logs (requires a Log Analytics workspace - not created here)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Prevent accidental Application Gateway deletion"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain for the TLS subject (falls back to localhost)"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "Backend port the VMSS listens on"
  type        = number
  default     = 80
}
