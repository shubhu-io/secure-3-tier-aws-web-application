# ============================================================================
# VPC module outputs
# ============================================================================

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_cidr" {
  description = "Virtual Network CIDR block"
  value       = azurerm_virtual_network.this.address_space[0]
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = azurerm_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = azurerm_subnet.db[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = azurerm_nat_gateway.this[*].id
}
