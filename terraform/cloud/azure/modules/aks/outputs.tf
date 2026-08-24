# ============================================================================
# AKS module outputs
# ============================================================================

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  description = "AKS API server endpoint"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to fetch the AKS kubeconfig"
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name}"
}
