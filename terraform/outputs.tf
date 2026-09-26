# ============================================================================
# Root outputs — AWS platform outputs.
# ============================================================================

output "app_url" {
  description = "Public URL of the application"
  value       = module.aws.app_url
}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = module.aws.lb_dns_name
}

output "db_host" {
  description = "RDS endpoint"
  value       = module.aws.db_host
  sensitive   = true
}

output "db_secret_ref" {
  description = "ARN of the Secrets Manager secret holding DB credentials"
  value       = module.aws.db_secret_ref
}

output "registry_url" {
  description = "ECR registry base URL"
  value       = module.aws.registry_url
}

output "image_repository_urls" {
  description = "Map of service name -> full ECR repository URL"
  value       = module.aws.image_repository_urls
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.aws.asg_name
}

output "topic_arn" {
  description = "SNS notification topic ARN"
  value       = module.aws.topic_arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.aws.dashboard_name
}

output "web_acl_arn" {
  description = "WAF web ACL ARN (empty if none)"
  value       = module.aws.web_acl_arn
}



output "cicd_policy_json" {
  description = "CI/CD IAM policy document that the pipeline principal should be granted"
  value       = module.aws.cicd_policy_json
}
