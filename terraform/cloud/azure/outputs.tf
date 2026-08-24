# ============================================================================
# Root outputs (Azure) - normalised across all clouds.
# ============================================================================

output "app_url" {
  description = "Public HTTPS URL of the application"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${module.alb.alb_dns_name}"
}

output "lb_dns_name" {
  description = "Application Gateway / load-balancer address"
  value       = module.alb.alb_dns_name
}

output "db_host" {
  description = "PostgreSQL server FQDN"
  value       = module.database.db_host
  sensitive   = true
}

output "db_secret_ref" {
  description = "Reference to the Key Vault secret holding DB credentials"
  value       = module.database.db_secret_ref
}

output "registry_url" {
  description = "ACR login server (e.g. myacr.azurecr.io)"
  value       = module.registry.login_server
}

output "image_repository_urls" {
  description = "Map of service name -> full ACR repository URL"
  value       = module.registry.repository_urls
}

output "asg_name" {
  description = "Virtual Machine Scale Set name"
  value       = module.compute.asg_name
}

output "topic_arn" {
  description = "Monitor action group id (notification target)"
  value       = module.monitoring.action_group_id
}

output "dashboard_name" {
  description = "Azure dashboard name/id"
  value       = module.monitoring.dashboard_name
}

output "web_acl_arn" {
  description = "WAF policy id (empty string if none)"
  value       = module.alb.web_acl_arn
}

output "kubeconfig_command" {
  description = "Command to fetch the AKS kubeconfig (empty when AKS disabled)"
  value       = var.enable_aks ? module.aks[0].kubeconfig_command : ""
}

output "cluster_endpoint" {
  description = "AKS cluster endpoint (empty when AKS disabled)"
  value       = var.enable_aks ? module.aks[0].cluster_endpoint : ""
  sensitive   = true
}

output "cicd_policy_json" {
  description = "JSON document listing the Azure RBAC role assignments the CI/CD principal needs"
  value = jsonencode({
    description  = "Least-privilege Azure RBAC the CI/CD principal requires to deploy this platform"
    principal_id = var.aks_ci_principal_id
    role_assignments = [
      {
        role  = "Contributor"
        scope = azurerm_resource_group.this.id
        note  = "Deploy/update resources inside the project resource group"
      },
      {
        role  = "AcrPush"
        scope = module.registry.acr_id
        note  = "Push container images to ACR"
      },
      {
        role  = "AcrPull"
        scope = module.registry.acr_id
        note  = "Pull container images from ACR (also granted to the VMSS identity)"
      },
      {
        role  = "Monitoring Contributor"
        scope = azurerm_resource_group.this.id
        note  = "Write metrics / manage alert rules"
      }
    ]
  })
}
