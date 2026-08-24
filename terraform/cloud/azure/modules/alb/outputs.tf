# ============================================================================
# ALB module outputs
# ============================================================================

output "alb_dns_name" {
  description = "Public IP FQDN of the Application Gateway"
  value       = azurerm_public_ip.appgw.fqdn
}

output "appgw_id" {
  description = "Application Gateway resource ID (for alarms)"
  value       = azurerm_application_gateway.this.id
}

output "public_ip_id" {
  description = "Application Gateway public IP resource ID"
  value       = azurerm_public_ip.appgw.id
}

output "web_acl_arn" {
  description = "WAF policy id (empty string if WAF disabled)"
  value       = var.enable_waf ? azurerm_web_application_firewall_policy.this[0].id : ""
}

output "backend_pool_ids" {
  description = "Application Gateway backend address pool IDs the VMSS joins"
  value       = [for pool in azurerm_application_gateway.this.backend_address_pool : pool.id]
}
