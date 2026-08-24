# ============================================================================
# Database module outputs
# ============================================================================

output "db_host" {
  description = "Cloud SQL private IP address (sensitive)"
  value       = google_sql_database_instance.this.private_ip_address
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = var.db_port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_secret_ref" {
  description = "Secret Manager secret id holding DB credentials"
  value       = google_secret_manager_secret.db_credentials.id
}

output "db_connection_name" {
  description = "Cloud SQL connection name (project:region:instance) for the Auth Proxy"
  value       = google_sql_database_instance.this.connection_name
}
