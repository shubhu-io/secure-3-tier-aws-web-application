# ============================================================================
# ALB module outputs
# ============================================================================

output "lb_dns_name" {
  description = "Load balancer IP address"
  value       = google_compute_global_address.app.address
}

output "app_url" {
  description = "Public URL of the application (domain with TLS, else http://IP)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${google_compute_global_address.app.address}"
}

output "web_acl_arn" {
  description = "Cloud Armor security policy id"
  value       = google_compute_security_policy.waf.id
}
