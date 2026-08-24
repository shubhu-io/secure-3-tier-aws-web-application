# ============================================================================
# Jenkins module - self-hosted CI/CD controller (alternative to GitHub Actions)
# ----------------------------------------------------------------------------
# Provisioned only when var.enable_jenkins is true (root invokes with count).
# Runs the LTS Jenkins controller container on a Debian VM in the app subnet
# with an external IP for the UI. The VM service account carries the roles a
# CI/CD principal needs (mirrors cicd_policy_json).
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "google_service_account" "jenkins" {
  account_id   = "${local.name_prefix}-jenkins"
  display_name = "${local.name_prefix} jenkins"
}

resource "google_project_iam_member" "jenkins" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/compute.admin",
    "roles/cloudsql.admin",
    "roles/monitoring.admin",
    "roles/secretmanager.secretAccessor",
  ])

  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_compute_firewall" "jenkins_ui" {
  name      = "${local.name_prefix}-jenkins-ui"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges = var.ingress_cidrs
  target_tags   = ["jenkins"]

  allow {
    protocol = "tcp"
    ports    = ["8080", "50000"]
  }
}

resource "google_compute_instance" "jenkins" {
  name         = "${local.name_prefix}-jenkins"
  machine_type = var.machine_type
  zone         = "${var.region}-a"

  tags = ["jenkins"]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
    }
  }

  network_interface {
    subnetwork = var.app_subnet_ids[0]
    access_config {}
  }

  service_account {
    email  = google_service_account.jenkins.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y docker.io jq curl
    systemctl enable --now docker
    docker run -d --restart unless-stopped --name jenkins \
      -p 8080:8080 -p 50000:50000 \
      -v jenkins_home:/var/jenkins_home \
      jenkins/jenkins:lts
  EOT

  depends_on = [google_project_iam_member.jenkins]
}
