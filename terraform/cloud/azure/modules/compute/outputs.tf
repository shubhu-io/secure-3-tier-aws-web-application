# ============================================================================
# Compute module outputs
# ============================================================================

output "asg_name" {
  description = "Virtual Machine Scale Set name"
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "asg_id" {
  description = "Virtual Machine Scale Set resource ID"
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "image_params" {
  description = "Map of service name -> full ACR image URL (the deploy pointer CI pushes to)"
  value       = local.image_params
}
