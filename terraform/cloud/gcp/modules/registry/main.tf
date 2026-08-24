# ============================================================================
# Registry module - Artifact Registry repositories (one per service)
# ----------------------------------------------------------------------------
# Images are pulled at runtime by the compute instances' service account (no
# embedded credentials). `registry_url` is the base host/path; the map gives
# the full per-service repository URL.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Base Artifact Registry host, e.g. europe-west1-docker.pkg.dev/<project>
  registry_url = "${var.region}-docker.pkg.dev/${var.project}"

  # Per-service full repository URL: <region>-docker.pkg.dev/<project>/<repo>
  image_repository_urls = {
    for repo in var.repositories :
    repo => "${local.registry_url}/${local.name_prefix}-${repo}"
  }
}

resource "google_artifact_registry_repository" "this" {
  for_each = toset(var.repositories)

  location      = var.region
  repository_id = "${local.name_prefix}-${each.key}"
  description   = "Docker repository for the ${each.key} service"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"
}
