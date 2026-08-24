# ============================================================================
# Database module outputs
# ============================================================================

output "db_host" {
  description = "RDS endpoint (hostname)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials + app secrets"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_instance_id" {
  description = "RDS instance identifier (for alarms)"
  value       = aws_db_instance.this.id
}
