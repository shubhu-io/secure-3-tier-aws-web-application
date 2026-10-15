# ============================================================================
# AWS root — instantiates the AWS cloud implementation.
# ============================================================================

module "aws" {
  source = "./cloud/aws"

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
  enable_waf                   = var.enable_waf
  enable_flow_logs             = var.enable_flow_logs
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
  enable_jenkins               = var.aws_enable_jenkins
  jenkins_instance_type        = var.aws_jenkins_instance_type
  jenkins_ingress_cidrs        = var.aws_jenkins_ingress_cidrs
  jenkins_key_name             = var.aws_jenkins_key_name
}
