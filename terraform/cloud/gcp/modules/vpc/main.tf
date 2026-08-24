# ============================================================================
# VPC module - GCP network foundation
# ----------------------------------------------------------------------------
# Custom-mode VPC (auto_create_subnetworks = false) + public/app/db subnetworks
# + Cloud NAT for outbound (private instances have no external IP) + a private
# services connection range placeholder for Cloud SQL.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Network (custom subnet mode)
# ---------------------------------------------------------------------------
resource "google_compute_network" "this" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# ---------------------------------------------------------------------------
# Subnetworks
# ---------------------------------------------------------------------------
resource "google_compute_subnetwork" "public" {
  count         = length(var.public_subnet_cidrs)
  name          = "${local.name_prefix}-public-${element(var.azs, count.index)}"
  ip_cidr_range = element(var.public_subnet_cidrs, count.index)
  region        = var.region
  network       = google_compute_network.this.id

  # Enable Private Google Access so private instances can reach GCP APIs/NAT
  private_ip_google_access = true

  # Needed for Cloud NAT to map external IPs to internal instances
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "app" {
  count         = length(var.app_subnet_cidrs)
  name          = "${local.name_prefix}-app-${element(var.azs, count.index)}"
  ip_cidr_range = element(var.app_subnet_cidrs, count.index)
  region        = var.region
  network       = google_compute_network.this.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db" {
  count         = length(var.db_subnet_cidrs)
  name          = "${local.name_prefix}-db-${element(var.azs, count.index)}"
  ip_cidr_range = element(var.db_subnet_cidrs, count.index)
  region        = var.region
  network       = google_compute_network.this.id

  private_ip_google_access = true
}

# ---------------------------------------------------------------------------
# Cloud NAT - outbound internet for private instances (no external IPs)
# ---------------------------------------------------------------------------
resource "google_compute_router" "this" {
  name    = "${local.name_prefix}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_address" "nat" {
  count  = var.nat_gateway_count
  name   = "${local.name_prefix}-nat-ip-${count.index + 1}"
  region = var.region
}

resource "google_compute_router_nat" "this" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat[*].self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
