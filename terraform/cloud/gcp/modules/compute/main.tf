# ============================================================================
# Compute module - instance template + managed instance group + autoscaler
# ----------------------------------------------------------------------------
# Private instances (no external IP) in the app subnets, fronted by Cloud NAT.
# Images are pulled from Artifact Registry via the VM service account. The
# Cloud SQL Auth Proxy (started in user-data) gives DB access on 127.0.0.1.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Service account - least privilege for what user-data needs
# ---------------------------------------------------------------------------
resource "google_service_account" "app" {
  account_id   = "${local.name_prefix}-app"
  display_name = "${local.name_prefix} app runtime"
}

resource "google_project_iam_member" "app" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudsql.client",
  ])

  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.app.email}"
}

# ---------------------------------------------------------------------------
# Instance template
# ---------------------------------------------------------------------------
resource "google_compute_instance_template" "app" {
  name         = "${local.name_prefix}-tpl"
  machine_type = var.machine_type

  tags = ["app"]

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-ssd"
  }

  network_interface {
    subnetwork = var.app_subnet_ids[0]
    # No access_config => no external IP (private instance, egress via Cloud NAT)
  }

  service_account {
    email  = google_service_account.app.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/user-data.sh", {
    project                    = var.project
    region                     = var.region
    db_secret_ref              = var.db_secret_ref
    app_port                   = var.app_port
    services_json              = jsonencode(var.services)
    image_repository_urls_json = jsonencode(var.image_repository_urls)
  })

  depends_on = [google_project_iam_member.app]
}

# ---------------------------------------------------------------------------
# Regional managed instance group
# ---------------------------------------------------------------------------
resource "google_compute_region_instance_group_manager" "app" {
  name   = "${local.name_prefix}-mig"
  region = var.region

  version {
    instance_template = google_compute_instance_template.app.id
  }

  base_instance_name = "${local.name_prefix}-app"
  target_size        = var.desired_capacity

  named_port {
    name = "http"
    port = var.app_port
  }
}

# ---------------------------------------------------------------------------
# Autoscaler - keep CPU around 70%
# ---------------------------------------------------------------------------
resource "google_compute_region_autoscaler" "app" {
  name   = "${local.name_prefix}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    min_replicas    = var.min_size
    max_replicas    = var.max_size
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}
