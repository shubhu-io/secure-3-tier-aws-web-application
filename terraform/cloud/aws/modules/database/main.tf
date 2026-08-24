# ============================================================================
# Database module - managed RDS + Secrets Manager
#
# Creates: RDS instance in private DB subnets, DB subnet group, the secret in
#          AWS Secrets Manager holding all runtime credentials for the app.
#
# The engine (postgres | mysql | mariadb), engine version and port come from
# stack.json (via the root module) so the whole stack follows the manifest.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Credentials - generated here, stored ONLY in Secrets Manager.
# random_password is stored in Terraform state; keep state in the encrypted
# S3 backend (see terraform/backend.tf) - never in the git repository.
# ---------------------------------------------------------------------------
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials + runtime secrets for the application"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username   = var.db_username
    password   = random_password.db_password.result
    host       = aws_db_instance.this.address
    port       = aws_db_instance.this.port
    dbname     = var.db_name
    jwt_secret = random_password.jwt_secret.result
  })
}

# ---------------------------------------------------------------------------
# DB subnet group (private DB subnets only)
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Enhanced Monitoring - RDS metrics to CloudWatch Logs (1-minute granularity)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "rds_enhanced_monitoring_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${local.name_prefix}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_assume.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------------------------------------
# RDS instance
# ---------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = var.db_multi_az

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  storage_encrypted        = true
  storage_type             = "gp3"
  delete_automated_backups = var.delete_automated_backups

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  deletion_protection       = var.deletion_protection

  performance_insights_enabled = false

  # Enhanced Monitoring: 1-minute OS-level metrics via CloudWatch Logs. This
  # requires the AmazonRDSEnhancedMonitoringRole and costs ~$0.03/hour (only
  # enable when not on free-tier constraints - see monitoring_interval below).
  monitoring_interval = var.enhanced_monitoring_interval
  monitoring_role_arn = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring.arn : null

  # Prevent Terraform from trying to manage external changes to the password
  lifecycle {
    ignore_changes = [password, engine_version]
  }

  tags = {
    Environment = var.environment
  }
}
