# ============================================================================
# GCP root module outputs - normalized for the multi-cloud dispatcher
# ============================================================================

output "app_url" {
  description = "Public URL of the application"
  value       = module.alb.app_url
}

output "lb_dns_name" {
  description = "Load balancer IP/address"
  value       = module.alb.lb_dns_name
}

output "db_host" {
  description = "Cloud SQL private IP/FQDN"
  value       = module.database.db_host
  sensitive   = true
}

output "db_secret_ref" {
  description = "Secret Manager secret id holding DB credentials"
  value       = module.database.db_secret_ref
}

output "registry_url" {
  description = "Artifact Registry base URL"
  value       = module.registry.registry_url
}

output "image_repository_urls" {
  description = "Map of service name -> full repository URL"
  value       = module.registry.image_repository_urls
}

output "asg_name" {
  description = "Managed instance group name"
  value       = module.compute.asg_name
}

output "topic_arn" {
  description = "Monitoring notification channel id"
  value       = module.monitoring.topic_arn
}

output "dashboard_name" {
  description = "Monitoring dashboard name/id"
  value       = module.monitoring.dashboard_name
}

output "web_acl_arn" {
  description = "Cloud Armor security policy id (empty string if none)"
  value       = module.alb.web_acl_arn
}

output "kubeconfig_command" {
  description = "Command to fetch kubeconfig for the GKE cluster (empty if k8s disabled)"
  value       = var.enable_gke ? module.gke[0].kubeconfig_command : ""
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint (empty if k8s disabled)"
  value       = var.enable_gke ? module.gke[0].cluster_endpoint : ""
  sensitive   = true
}

output "cicd_policy_json" {
  description = "CI/CD IAM roles the pipeline principal needs, as a JSON document"
  value = jsonencode([
    "roles/artifactregistry.writer",
    "roles/compute.admin",
    "roles/cloudsql.admin",
    "roles/monitoring.admin",
    "roles/secretmanager.secretAccessor"
  ])
}
