# ============================================================================
# Database module - Cloud SQL PostgreSQL + Secret Manager
# ----------------------------------------------------------------------------
# Private IP only (no public IP) via the VPC private service connection.
# Credentials are generated here and stored ONLY in Secret Manager (no creds
# in code). The app reaches the DB through the Cloud SQL Auth Proxy, which
# authenticates with the instance using the VM service account.
# ============================================================================

locals {
  name_prefix      = "${var.project_name}-${var.environment}"
  db_instance_name = "${local.name_prefix}-db"
}

# ---------------------------------------------------------------------------
# Private service connection to Cloud SQL (VPC peering for private IP)
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "private_service_networking" {
  name          = "${local.name_prefix}-psc-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id
}

resource "google_service_networking_connection" "private_service" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_networking.name]
}

# ---------------------------------------------------------------------------
# Generated credentials (stored in state - keep state encrypted, never in git)
# ---------------------------------------------------------------------------
resource "random_password" "db_password" {
  length      = 24
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

# ---------------------------------------------------------------------------
# Secret Manager - holds the runtime credentials the app reads at boot
# ---------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${local.name_prefix}-db-credentials"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username        = var.db_username
    password        = random_password.db_password.result
    host            = google_sql_database_instance.this.private_ip_address
    port            = var.db_port
    dbname          = var.db_name
    connection_name = google_sql_database_instance.this.connection_name
    jwt_secret      = random_password.jwt_secret.result
  })
}

# ---------------------------------------------------------------------------
# Cloud SQL instance (PostgreSQL, private IP only)
# ---------------------------------------------------------------------------
resource "google_sql_database_instance" "this" {
  name             = local.db_instance_name
  database_version = "POSTGRES_16"
  region           = var.region

  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.db_tier
    availability_type     = var.db_multi_az ? "REGIONAL" : "ZONAL"
    disk_size             = var.db_allocated_storage
    disk_autoresize       = true
    disk_autoresize_limit = var.db_allocated_storage * 5

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = false
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = false
    }
  }

  depends_on = [google_service_networking_connection.private_service]
}

resource "google_sql_database" "this" {
  name     = var.db_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "this" {
  name     = var.db_username
  instance = google_sql_database_instance.this.name
  password = random_password.db_password.result
}
