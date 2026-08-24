# ============================================================================
# Compute module outputs
# ============================================================================

output "asg_name" {
  description = "Managed instance group name"
  value       = google_compute_region_instance_group_manager.app.name
}

output "instance_group" {
  description = "Instance group self_link (used as the LB backend)"
  value       = google_compute_region_instance_group_manager.app.instance_group
}

output "service_account_email" {
  description = "Runtime service account email"
  value       = google_service_account.app.email
}
