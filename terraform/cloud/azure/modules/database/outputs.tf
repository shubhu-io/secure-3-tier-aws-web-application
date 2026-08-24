# ============================================================================
# Database module outputs
# ============================================================================

output "db_host" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "db_server_id" {
  description = "PostgreSQL Flexible Server resource ID (for alarms)"
  value       = azurerm_postgresql_flexible_server.this.id
}

output "db_secret_ref" {
  description = "Key Vault secret ID holding DB credentials + runtime secrets"
  value       = azurerm_key_vault_secret.db_credentials.id
}

output "db_secret_name" {
  description = "Key Vault secret name (the VMSS fetches this at boot)"
  value       = azurerm_key_vault_secret.db_credentials.name
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}
