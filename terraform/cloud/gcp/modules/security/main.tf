# ============================================================================
# Security module - layered GCP firewall rules
# ----------------------------------------------------------------------------
#   Internet --(LB health ranges)--> app:app_port
#   app subnet --------------------------> db:5432
#   (optional GKE node tag) ------------> db:5432
#   IAP (35.235.240.0/20) --------------> app:22  (browser SSH, no open SSH)
#
# Mirrors the AWS ALB -> App -> DB security-group layering. Cloud SQL private
# IP lives in the VPC-peered range; the app-tier ingress rule restricts 5432
# to the application subnet (and GKE nodes when enabled).
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Load balancer / health checks -> app on the app port -------------------
resource "google_compute_firewall" "lb_to_app" {
  name      = "${local.name_prefix}-lb-to-app"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges = var.lb_health_check_ranges
  target_tags   = ["app"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }
}

# --- Application tier -> database on 5432 (restricted to app subnet) --------
resource "google_compute_firewall" "app_to_db" {
  name      = "${local.name_prefix}-app-to-db"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges = var.app_subnet_cidrs
  target_tags   = ["db"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.db_port)]
  }
}

# --- Optional: GKE nodes -> database on 5432 -------------------------------
resource "google_compute_firewall" "gke_to_db" {
  count     = length(var.db_ingress_source_tags) > 0 ? 1 : 0
  name      = "${local.name_prefix}-gke-to-db"
  network   = var.network_id
  direction = "INGRESS"

  source_tags = var.db_ingress_source_tags
  target_tags = ["db"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.db_port)]
  }
}

# --- IAP SSH (browser-based, no public SSH port) ----------------------------
resource "google_compute_firewall" "iap_ssh" {
  count     = var.enable_ssh_iap ? 1 : 0
  name      = "${local.name_prefix}-iap-ssh"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges = [var.iap_source_range]
  target_tags   = ["app"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# --- Internal instance-to-instance traffic (health checks, meshes) ----------
resource "google_compute_firewall" "internal" {
  name      = "${local.name_prefix}-internal"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges = [var.vpc_cidr]
  target_tags   = ["app"]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

# --- Explicit egress allow (GCP default is allow; stated for parity) --------
resource "google_compute_firewall" "egress_all" {
  name      = "${local.name_prefix}-egress-all"
  network   = var.network_id
  direction = "EGRESS"

  target_tags = ["app"]

  allow {
    protocol = "all"
  }
}
