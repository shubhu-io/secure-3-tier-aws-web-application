# ============================================================================
# GCP root module - wires every component together
# ============================================================================

# ---------------------------------------------------------------------------
# 1. Network
# ---------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  nat_gateway_count   = var.nat_gateway_count
}

# ---------------------------------------------------------------------------
# 2. Security (firewall rules) - layered ALB -> App -> DB
# ---------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name           = var.project_name
  environment            = var.environment
  network_id             = module.vpc.network_id
  app_port               = local.app_port
  db_port                = local.db_port
  app_subnet_cidrs       = var.app_subnet_cidrs
  vpc_cidr               = var.vpc_cidr
  db_ingress_source_tags = var.enable_gke ? ["gke-node"] : []
  enable_ssh_iap         = true
}

# ---------------------------------------------------------------------------
# 3. Container registry (Artifact Registry)
# ---------------------------------------------------------------------------
module "registry" {
  source = "./modules/registry"

  project_name = var.project_name
  environment  = var.environment
  project      = var.project
  region       = var.region
  repositories = var.repositories
}

# ---------------------------------------------------------------------------
# 4. Database (Cloud SQL + Secret Manager)
# ---------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  project               = var.project
  region                = var.region
  network_id            = module.vpc.network_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_tier               = var.db_tier
  db_allocated_storage  = var.db_allocated_storage
  backup_retention_days = var.backup_retention_days
  deletion_protection   = var.deletion_protection
  skip_final_snapshot   = var.skip_final_snapshot
  db_multi_az           = var.db_multi_az
  db_port               = local.db_port
}

# ---------------------------------------------------------------------------
# 5. Compute (instance template + MIG + autoscaler)
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  project               = var.project
  region                = var.region
  app_subnet_ids        = module.vpc.app_subnet_ids
  app_port              = local.app_port
  services              = local.services
  machine_type          = var.machine_type
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  image_repository_urls = module.registry.image_repository_urls
  db_secret_ref         = module.database.db_secret_ref
  db_port               = local.db_port
}

# ---------------------------------------------------------------------------
# 6. Load balancer + WAF (references the MIG created above)
# ---------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name            = var.project_name
  environment             = var.environment
  region                  = var.region
  app_port                = local.app_port
  instance_group          = module.compute.instance_group
  domain_name             = var.domain_name
  enable_waf              = true
  alb_deletion_protection = var.alb_deletion_protection
  enable_access_logs      = var.enable_alb_access_logs
}

# ---------------------------------------------------------------------------
# 7. Monitoring (channel + alerts + dashboard)
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  notification_email = var.notification_email
  asg_name           = module.compute.asg_name
  region             = var.region
}

# ---------------------------------------------------------------------------
# 8. Kubernetes (optional) - GKE cluster + node pool
# ---------------------------------------------------------------------------
module "gke" {
  count = var.enable_gke ? 1 : 0

  source = "./modules/gke"

  project_name       = var.project_name
  environment        = var.environment
  project            = var.project
  region             = var.region
  network_id         = module.vpc.network_id
  app_subnet_ids     = module.vpc.app_subnet_ids
  machine_type       = var.gke_machine_type
  node_count         = var.gke_node_count
  kubernetes_version = var.gke_kubernetes_version
  gke_node_tags      = ["gke-node"]
}

# ---------------------------------------------------------------------------
# 9. Jenkins (optional) - self-hosted CI/CD controller
# ---------------------------------------------------------------------------
module "jenkins" {
  count = var.enable_jenkins ? 1 : 0

  source = "./modules/jenkins"

  project_name   = var.project_name
  environment    = var.environment
  project        = var.project
  region         = var.region
  network_id     = module.vpc.network_id
  app_subnet_ids = module.vpc.app_subnet_ids
  machine_type   = var.jenkins_machine_type
  ingress_cidrs  = var.jenkins_ingress_cidrs
}
