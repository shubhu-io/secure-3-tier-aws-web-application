# ============================================================================
# Security module outputs
# ============================================================================

output "public_nsg_id" {
  description = "Public (Application Gateway) NSG ID"
  value       = azurerm_network_security_group.public.id
}

output "app_nsg_id" {
  description = "Application NSG ID"
  value       = azurerm_network_security_group.app.id
}

output "db_nsg_id" {
  description = "Database NSG ID"
  value       = azurerm_network_security_group.db.id
}
