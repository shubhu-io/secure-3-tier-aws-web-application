# ============================================================================
# Multi-cloud root - dispatches to exactly one cloud implementation.
#
# Only the selected cloud's child module is instantiated (count = 0 for the
# others), so its provider is the only one that needs credentials at plan time.
# ============================================================================

module "aws" {
  source = "./cloud/aws"
  count  = var.cloud == "aws" ? 1 : 0

  providers = { aws = aws }

  project_name                 = var.project_name
  environment                  = var.environment
  aws_region                   = var.aws_region
  azs                          = var.azs
  vpc_cidr                     = var.vpc_cidr
  public_subnet_cidrs          = var.public_subnet_cidrs
  app_subnet_cidrs             = var.app_subnet_cidrs
  db_subnet_cidrs              = var.db_subnet_cidrs
  nat_gateway_count            = var.nat_gateway_count
  alb_deletion_protection      = var.alb_deletion_protection
  enable_alb_access_logs       = var.enable_alb_access_logs
  instance_type                = var.aws_instance_type
  asg_min_size                 = var.asg_min_size
  asg_max_size                 = var.asg_max_size
  asg_desired_capacity         = var.asg_desired_capacity
  db_instance_class            = var.aws_db_instance_class
  db_multi_az                  = var.db_multi_az
  db_allocated_storage         = var.db_allocated_storage
  db_name                      = var.db_name
  db_username                  = var.db_username
  backup_retention_days        = var.backup_retention_days
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  enhanced_monitoring_interval = var.aws_enhanced_monitoring_interval
  domain_name                  = var.domain_name
  notification_email           = var.notification_email
  repositories                 = var.repositories
  ecr_push_principal_arns      = var.aws_ecr_push_principal_arns
  enable_eks                   = var.aws_enable_eks
  eks_cluster_version          = var.aws_eks_cluster_version
  eks_node_instance_types      = var.aws_eks_node_instance_types
  eks_node_min_size            = var.aws_eks_node_min_size
  eks_node_desired_size        = var.aws_eks_node_desired_size
  eks_node_max_size            = var.aws_eks_node_max_size
  eks_ci_iam_arn               = var.aws_eks_ci_iam_arn
  enable_jenkins               = var.aws_enable_jenkins
  jenkins_instance_type        = var.aws_jenkins_instance_type
  jenkins_ingress_cidrs        = var.aws_jenkins_ingress_cidrs
  jenkins_key_name             = var.aws_jenkins_key_name
  jenkins_kubectl_version      = var.aws_jenkins_kubectl_version
}

module "azure" {
  source = "./cloud/azure"
  count  = var.cloud == "azure" ? 1 : 0

  providers = { azurerm = azurerm }

  project_name            = var.project_name
  environment             = var.environment
  location                = var.azure_location
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnet_cidrs     = var.public_subnet_cidrs
  app_subnet_cidrs        = var.app_subnet_cidrs
  db_subnet_cidrs         = var.db_subnet_cidrs
  nat_gateway_count       = var.nat_gateway_count
  alb_deletion_protection = var.alb_deletion_protection
  enable_alb_access_logs  = var.enable_alb_access_logs
  domain_name             = var.domain_name
  notification_email      = var.notification_email
  repositories            = var.repositories
  db_name                 = var.db_name
  db_username             = var.db_username
  db_multi_az             = var.db_multi_az
  db_allocated_storage    = var.db_allocated_storage
  backup_retention_days   = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  asg_min_size            = var.asg_min_size
  asg_max_size            = var.asg_max_size
  asg_desired_capacity    = var.asg_desired_capacity
  vm_size                 = var.azure_vm_size
  db_sku                  = var.azure_db_sku
  enable_aks              = var.azure_enable_aks
  aks_node_count          = var.azure_aks_node_count
  aks_node_vm_size        = var.azure_aks_node_vm_size
  aks_kubernetes_version  = var.azure_aks_kubernetes_version
  aks_ci_principal_id     = var.azure_aks_ci_principal_id
  enable_jenkins          = var.azure_enable_jenkins
  jenkins_vm_size         = var.azure_jenkins_vm_size
  jenkins_ingress_cidrs   = var.azure_jenkins_ingress_cidrs
  jenkins_admin_username  = var.azure_jenkins_admin_username
}

module "gcp" {
  source = "./cloud/gcp"
  count  = var.cloud == "gcp" ? 1 : 0

  providers = { google = google }

  project                 = var.gcp_project
  environment             = var.environment
  project_name            = var.project_name
  region                  = var.gcp_region
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnet_cidrs     = var.public_subnet_cidrs
  app_subnet_cidrs        = var.app_subnet_cidrs
  db_subnet_cidrs         = var.db_subnet_cidrs
  nat_gateway_count       = var.nat_gateway_count
  alb_deletion_protection = var.alb_deletion_protection
  enable_alb_access_logs  = var.enable_alb_access_logs
  domain_name             = var.domain_name
  notification_email      = var.notification_email
  repositories            = var.repositories
  db_name                 = var.db_name
  db_username             = var.db_username
  db_multi_az             = var.db_multi_az
  db_allocated_storage    = var.db_allocated_storage
  backup_retention_days   = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  asg_min_size            = var.asg_min_size
  asg_max_size            = var.asg_max_size
  asg_desired_capacity    = var.asg_desired_capacity
  machine_type            = var.gcp_machine_type
  db_tier                 = var.gcp_db_tier
  enable_gke              = var.gcp_enable_gke
  gke_node_count          = var.gcp_gke_node_count
  gke_machine_type        = var.gcp_gke_machine_type
  gke_kubernetes_version  = var.gcp_gke_kubernetes_version
  enable_jenkins          = var.gcp_enable_jenkins
  jenkins_machine_type    = var.gcp_jenkins_machine_type
  jenkins_ingress_cidrs   = var.gcp_jenkins_ingress_cidrs
}
