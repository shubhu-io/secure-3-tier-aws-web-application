# ============================================================================
# Root module (Azure) - wires every component together.
#
#   vnet+subnets+NAT  ->  NSGs  ->  ACR  ->  PostgreSQL+Key Vault
#   ->  VMSS (pulls from ACR via managed identity)  ->  App Gateway + WAF
#   ->  Monitoring (action group + metric alerts + dashboard)
#   optional: AKS, Jenkins
# ============================================================================

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource group - everything lives here.
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# 1. Network
# ---------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_cidr           = var.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  nat_gateway_count   = var.nat_gateway_count
}

# ---------------------------------------------------------------------------
# 2. Security groups (layered: appgw -> app -> db)
# ---------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_id             = module.vpc.vnet_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  app_subnet_ids      = module.vpc.app_subnet_ids
  db_subnet_ids       = module.vpc.db_subnet_ids
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  db_port             = local.db_port
}

# ---------------------------------------------------------------------------
# 3. Container registry (ACR, admin disabled + RBAC)
# ---------------------------------------------------------------------------
module "registry" {
  source = "./modules/registry"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  repositories        = var.repositories
}

# ---------------------------------------------------------------------------
# 4. Database (PostgreSQL Flexible Server + Key Vault for credentials)
# ---------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name            = var.project_name
  environment             = var.environment
  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  vnet_id                 = module.vpc.vnet_id
  db_subnet_id            = module.vpc.db_subnet_ids[0]
  db_sku                  = var.db_sku
  pg_version              = local.pg_version
  db_name                 = var.db_name
  db_username             = var.db_username
  db_allocated_storage_gb = var.db_allocated_storage
  backup_retention_days   = var.backup_retention_days
  db_multi_az             = var.db_multi_az
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
}

# ---------------------------------------------------------------------------
# 5. Compute (VMSS + autoscale, pulls images from ACR via managed identity)
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  app_subnet_ids         = module.vpc.app_subnet_ids
  app_nsg_id             = module.security.app_nsg_id
  acr_id                 = module.registry.acr_id
  acr_login_server       = module.registry.login_server
  key_vault_id           = module.database.key_vault_id
  key_vault_name         = module.database.key_vault_name
  db_secret_name         = module.database.db_secret_name
  db_host                = module.database.db_host
  services               = local.services
  vm_size                = var.vm_size
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  zones                  = local.azs
  health_check_path      = "/health"
  appgw_backend_pool_ids = module.alb.backend_pool_ids
}

# ---------------------------------------------------------------------------
# 6. Load balancer + WAF (Application Gateway)
# ---------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  public_subnet_id           = module.vpc.public_subnet_ids[0]
  appgw_nsg_id               = module.security.public_nsg_id
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  deployer_object_id         = data.azurerm_client_config.current.object_id
  enable_waf                 = true
  enable_access_logs         = var.enable_alb_access_logs
  enable_deletion_protection = var.alb_deletion_protection
  domain_name                = var.domain_name
  app_port                   = 80
}

# ---------------------------------------------------------------------------
# 7. Monitoring (action group + metric alerts + dashboard)
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  notification_email      = var.notification_email
  asg_id                  = module.compute.asg_id
  lb_id                   = module.alb.appgw_id
  db_id                   = module.database.db_server_id
  db_allocated_storage_gb = var.db_allocated_storage
}

# ---------------------------------------------------------------------------
# 8. Kubernetes (optional) - AKS cluster + node pool
# ---------------------------------------------------------------------------
module "aks" {
  count = var.enable_aks ? 1 : 0

  source = "./modules/aks"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  app_subnet_ids      = module.vpc.app_subnet_ids
  node_count          = var.aks_node_count
  node_vm_size        = var.aks_node_vm_size
  kubernetes_version  = var.aks_kubernetes_version
  ci_principal_id     = var.aks_ci_principal_id
  db_subnet_ids       = module.vpc.db_subnet_ids
}

# ---------------------------------------------------------------------------
# 9. Jenkins (optional) - self-hosted CI/CD controller
# ---------------------------------------------------------------------------
module "jenkins" {
  count = var.enable_jenkins ? 1 : 0

  source = "./modules/jenkins"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  public_subnet_id    = module.vpc.public_subnet_ids[0]
  ingress_cidrs       = var.jenkins_ingress_cidrs
  admin_username      = var.jenkins_admin_username
  vm_size             = var.jenkins_vm_size
  cicd_rg_scope       = azurerm_resource_group.this.id
}

# ---------------------------------------------------------------------------
# 10. CI/CD role assignments for the pipeline principal (least privilege).
#     Only created when a CI principal object id is supplied. The same set is
#     described in the cicd_policy_json output below.
# ---------------------------------------------------------------------------
locals {
  cicd_assignments = var.aks_ci_principal_id != "" ? {
    contributor = { role = "Contributor", scope = azurerm_resource_group.this.id }
    acrpush     = { role = "AcrPush", scope = module.registry.acr_id }
    acrpull     = { role = "AcrPull", scope = module.registry.acr_id }
    monitor     = { role = "Monitoring Contributor", scope = azurerm_resource_group.this.id }
  } : {}
}

resource "azurerm_role_assignment" "cicd" {
  for_each = local.cicd_assignments

  principal_id         = var.aks_ci_principal_id
  role_definition_name = each.value.role
  scope                = each.value.scope
}
