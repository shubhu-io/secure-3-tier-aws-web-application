# ============================================================================
# GKE module - private GKE Standard cluster + node pool
# ----------------------------------------------------------------------------
# Provisioned only when var.enable_gke is true (root invokes this module with
# count). The node pool carries a network tag (default "gke-node") that the
# root passes to the security module so pods can reach Cloud SQL on 5432.
# ============================================================================

locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  cluster_name       = "${local.name_prefix}-gke"
  kubeconfig_command = "gcloud container clusters get-credentials ${local.cluster_name} --region ${var.region} --project ${var.project}"
}

resource "google_container_cluster" "this" {
  name                     = local.cluster_name
  location                 = var.region
  initial_node_count       = 1
  remove_default_node_pool = true

  network    = var.network_id
  subnetwork = var.app_subnet_ids[0]

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }
}

resource "google_container_node_pool" "this" {
  name       = "${local.name_prefix}-np"
  cluster    = google_container_cluster.this.name
  location   = var.region
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    tags         = var.gke_node_tags
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
