# ============================================================================
# Registry module (Azure Container Registry).
#
# Creates a single ACR with admin disabled + RBAC. Unlike ECR, ACR does not
# have a distinct "repository" resource - repositories are created on first
# image push - so we expose the per-service repository URL by convention.
# Push/pull permissions are granted via RBAC role assignments in the compute
# and root modules (AcrPush for CI, AcrPull for the VMSS identity).
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  acr_name    = "${lower(replace(var.project_name, "-", ""))}${lower(replace(var.environment, "-", ""))}acr"
}

resource "azurerm_container_registry" "this" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = {
    Environment = var.environment
  }
}

# Per-service repository URLs (created on first push by the CI pipeline).
output "repository_urls" {
  description = "Map of repository key to full ACR repository URL"
  value = {
    for key in var.repositories :
    key => "${azurerm_container_registry.this.login_server}/${key}"
  }
}

output "acr_id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "ACR name"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "ACR login server (e.g. myacr.azurecr.io)"
  value       = azurerm_container_registry.this.login_server
}
