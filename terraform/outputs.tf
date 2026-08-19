# ============================================================================
# Root outputs
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer (also the app URL when no custom domain)"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "HTTPS URL of the application"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "db_host" {
  description = "RDS endpoint"
  value       = module.database.db_host
  sensitive   = true
}

output "db_secret_arn" {
  description = "Secrets Manager ARN with DB credentials"
  value       = module.database.db_secret_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "image_params" {
  description = "Map of service name -> SSM parameter holding its deployed image URI"
  value       = module.compute.image_params
}

output "ecr_repository_urls" {
  description = "Map of ECR repository -> URL"
  value       = module.ecr.repository_urls
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.monitoring.sns_topic_arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.monitoring.dashboard_name
}

output "web_acl_arn" {
  description = "WAF web ACL ARN"
  value       = module.alb.web_acl_arn
}

# --- Kubernetes (only populated when enable_eks = true) ---
output "eks_cluster_name" {
  description = "EKS cluster name (used by `aws eks update-kubeconfig`)"
  value       = var.enable_eks ? module.eks[0].cluster_name : ""
}

output "eks_cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : ""
  sensitive   = true
}

output "eks_connect_command" {
  description = "Command to connect kubectl to the EKS cluster"
  value       = var.enable_eks ? "aws eks update-kubeconfig --name ${module.eks[0].cluster_name} --region ${var.aws_region}" : ""
}

# --- Jenkins (only populated when enable_jenkins = true) ---
output "jenkins_url" {
  description = "Jenkins controller URL"
  value       = var.enable_jenkins ? module.jenkins[0].jenkins_url : ""
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins controller"
  value       = var.enable_jenkins ? module.jenkins[0].jenkins_public_ip : ""
}
