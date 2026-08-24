# ============================================================================
# Monitoring module outputs
# ============================================================================

output "topic_arn" {
  description = "Monitoring notification channel id"
  value       = google_monitoring_notification_channel.email.id
}

output "dashboard_name" {
  description = "Monitoring dashboard name/id"
  value       = google_monitoring_dashboard.overview.id
}
