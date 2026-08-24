# ============================================================================
# Root outputs - normalised across all clouds.
#
# Each cloud module exposes the same logical output names; we just pick the
# active one with a ternary.
# ============================================================================

output "cloud" {
  description = "Selected cloud provider"
  value       = var.cloud
}

output "app_url" {
  description = "Public URL of the application"
  value       = var.cloud == "aws" ? module.aws[0].app_url : var.cloud == "azure" ? module.azure[0].app_url : module.gcp[0].app_url
}

output "lb_dns_name" {
  description = "Load balancer address"
  value       = var.cloud == "aws" ? module.aws[0].lb_dns_name : var.cloud == "azure" ? module.azure[0].lb_dns_name : module.gcp[0].lb_dns_name
}

output "db_host" {
  description = "Database endpoint"
  value       = var.cloud == "aws" ? module.aws[0].db_host : var.cloud == "azure" ? module.azure[0].db_host : module.gcp[0].db_host
  sensitive   = true
}

output "db_secret_ref" {
  description = "Reference (ARN / ID / name) of the secret holding DB credentials"
  value       = var.cloud == "aws" ? module.aws[0].db_secret_ref : var.cloud == "azure" ? module.azure[0].db_secret_ref : module.gcp[0].db_secret_ref
}

output "registry_url" {
  description = "Container registry base URL"
  value       = var.cloud == "aws" ? module.aws[0].registry_url : var.cloud == "azure" ? module.azure[0].registry_url : module.gcp[0].registry_url
}

output "image_repository_urls" {
  description = "Map of service name -> full container image repository URL"
  value       = var.cloud == "aws" ? module.aws[0].image_repository_urls : var.cloud == "azure" ? module.azure[0].image_repository_urls : module.gcp[0].image_repository_urls
}

output "asg_name" {
  description = "Autoscaling group / scale set / instance group name"
  value       = var.cloud == "aws" ? module.aws[0].asg_name : var.cloud == "azure" ? module.azure[0].asg_name : module.gcp[0].asg_name
}

output "topic_arn" {
  description = "Notification topic (SNS / Event Grid / PubSub)"
  value       = var.cloud == "aws" ? module.aws[0].topic_arn : var.cloud == "azure" ? module.azure[0].topic_arn : module.gcp[0].topic_arn
}

output "dashboard_name" {
  description = "Monitoring dashboard name / ID"
  value       = var.cloud == "aws" ? module.aws[0].dashboard_name : var.cloud == "azure" ? module.azure[0].dashboard_name : module.gcp[0].dashboard_name
}

output "web_acl_arn" {
  description = "WAF web ACL reference (empty if none)"
  value       = var.cloud == "aws" ? module.aws[0].web_acl_arn : var.cloud == "azure" ? module.azure[0].web_acl_arn : module.gcp[0].web_acl_arn
}

output "kubeconfig_command" {
  description = "Command to fetch kubeconfig for the managed Kubernetes cluster (empty if k8s disabled)"
  value       = var.cloud == "aws" ? module.aws[0].kubeconfig_command : var.cloud == "azure" ? module.azure[0].kubeconfig_command : module.gcp[0].kubeconfig_command
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint (empty if k8s disabled)"
  value       = var.cloud == "aws" ? module.aws[0].cluster_endpoint : var.cloud == "azure" ? module.azure[0].cluster_endpoint : module.gcp[0].cluster_endpoint
  sensitive   = true
}

output "cicd_policy_json" {
  description = "CI/CD permission policy/document that the pipeline principal should be granted"
  value       = var.cloud == "aws" ? module.aws[0].cicd_policy_json : var.cloud == "azure" ? module.azure[0].cicd_policy_json : module.gcp[0].cicd_policy_json
}
