# ============================================================================
# Security module outputs
# ============================================================================

output "lb_to_app_fw_id" {
  description = "Firewall rule id: load balancer -> app"
  value       = google_compute_firewall.lb_to_app.id
}

output "app_to_db_fw_id" {
  description = "Firewall rule id: app -> db"
  value       = google_compute_firewall.app_to_db.id
}
