# ============================================================================
# AKS module (optional) - managed Kubernetes on Azure.
#
# Creates an AKS cluster with a system node pool in the private app subnet and
# (optionally) grants the CI/CD principal cluster-admin so pipelines can
# kubectl. The cluster endpoint is surfaced for the kubeconfig command.
# ============================================================================

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-aks"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.name_prefix
  kubernetes_version  = var.kubernetes_version
  # Local accounts disabled -> AAD / RBAC only.
  local_account_disabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.app_subnet_ids[0]
    zones               = slice(var.zones, 0, min(length(var.zones), 3))
    enable_auto_scaling = false
    os_disk_size_gb     = 50
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  tags = {
    Environment = var.environment
  }
}

# Grant the CI/CD principal cluster access (optional).
resource "azurerm_role_assignment" "ci" {
  count                = var.ci_principal_id != "" ? 1 : 0
  principal_id         = var.ci_principal_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  scope                = azurerm_kubernetes_cluster.this.id
}
