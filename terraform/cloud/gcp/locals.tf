# ============================================================================
# GCP root module locals
# ----------------------------------------------------------------------------
# path.root is the `terraform/` directory (this module is a child of the root
# dispatcher), so `../stack.json` resolves to the repo root - matching AWS.
# When validated/planned standalone from this directory we also try deeper
# relative paths (same fallback chain as the AWS/Azure modules).
# ============================================================================

locals {
  stack_file = try(
    file("${path.root}/../stack.json"),
    file("${path.root}/../../stack.json"),
    file("${path.root}/../../../stack.json"),
    file("${path.root}/../../../../stack.json"),
    file("${path.root}/stack.json"),
  )
  stack = jsondecode(local.stack_file)

  # Application services from the manifest
  services = local.stack.services

  # PostgreSQL
  db_port = lookup(local.stack.database, "port", 5432)

  # Default zones when none supplied
  azs = var.azs == null ? ["${var.region}-a", "${var.region}-b"] : var.azs

  name_prefix = "${var.project_name}-${var.environment}"

  # The load balancer / health checks target the (public) frontend on port 80
  app_port = 80

  # GCP external HTTP(S) LB health checks originate from these ranges
  lb_health_check_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  # IAP range for browser-based SSH (no public SSH)
  iap_source_range = "35.235.240.0/20"
}
