# ============================================================================
# Monitoring module outputs
# ============================================================================

output "action_group_id" {
  description = "Monitor action group id (notification topic)"
  value       = azurerm_monitor_action_group.this.id
}

output "dashboard_name" {
  description = "Azure dashboard name/id"
  value       = azurerm_portal_dashboard.overview.name
}
