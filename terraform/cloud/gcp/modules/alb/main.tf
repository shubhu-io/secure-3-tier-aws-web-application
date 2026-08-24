# ============================================================================
# ALB module - external HTTP(S) load balancer + Cloud Armor WAF
# ----------------------------------------------------------------------------
# Global external LB (premium tier) with a static IP. When a domain_name is
# supplied we provision a managed SSL certificate + HTTPS listener and an HTTP
# -> HTTPS redirect; otherwise a plain HTTP listener is used (dev).
#
# The WAF is a Cloud Armor security policy (preconfigured SQLi/XSS rules +
# default allow) attached to the backend service.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Static IP for the load balancer
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "app" {
  name         = "${local.name_prefix}-lb-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# ---------------------------------------------------------------------------
# Health check (GCP LB health checks originate from 130.211.0.0/22 + 35.191...)
# ---------------------------------------------------------------------------
resource "google_compute_health_check" "app" {
  name = "${local.name_prefix}-hc"

  http_health_check {
    port         = var.app_port
    request_path = var.health_check_path
  }
}

# ---------------------------------------------------------------------------
# Backend service (regional MIG as backend)
# ---------------------------------------------------------------------------
resource "google_compute_backend_service" "app" {
  name                  = "${local.name_prefix}-be"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.app.id]

  security_policy = google_compute_security_policy.waf.id

  backend {
    group = var.instance_group
  }
}

# ---------------------------------------------------------------------------
# URL maps: app routing + (optional) HTTP->HTTPS redirect
# ---------------------------------------------------------------------------
resource "google_compute_url_map" "app" {
  name            = "${local.name_prefix}-urlmap"
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_url_map" "redirect" {
  count = var.domain_name != "" ? 1 : 0

  name = "${local.name_prefix}-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# ---------------------------------------------------------------------------
# Cloud Armor WAF policy
# ---------------------------------------------------------------------------
resource "google_compute_security_policy" "waf" {
  name = "${local.name_prefix}-waf"

  # Default rule: allow everything not blocked by the WAF rules below
  rule {
    action   = "allow"
    priority = "2147483647"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default allow"
  }

  # Preconfigured WAF: block SQLi / XSS via Cloud Armor's managed rule sets
  rule {
    action   = "deny(403)"
    priority = "1000"

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-stable') || evaluatePreconfiguredWaf('xss-stable')"
      }
    }

    description = "OWASP CRS (sqli/xss) via Cloud Armor preconfigured WAF"
  }
}

# ---------------------------------------------------------------------------
# Proxies + managed SSL certificate
# ---------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "app" {
  count = var.domain_name != "" ? 1 : 0

  name = "${local.name_prefix}-cert"

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_target_https_proxy" "app" {
  count = var.domain_name != "" ? 1 : 0

  name             = "${local.name_prefix}-https-proxy"
  url_map          = google_compute_url_map.app.id
  ssl_certificates = [google_compute_managed_ssl_certificate.app[0].id]
}

resource "google_compute_target_http_proxy" "app" {
  name    = "${local.name_prefix}-http-proxy"
  url_map = var.domain_name != "" ? google_compute_url_map.redirect[0].id : google_compute_url_map.app.id
}

# ---------------------------------------------------------------------------
# Global forwarding rules (port 80 always; port 443 when TLS)
# ---------------------------------------------------------------------------
resource "google_compute_global_forwarding_rule" "https" {
  count = var.domain_name != "" ? 1 : 0

  name        = "${local.name_prefix}-https-fwd"
  ip_protocol = "TCP"
  port_range  = "443"
  target      = google_compute_target_https_proxy.app[0].id
  ip_address  = google_compute_global_address.app.address
}

resource "google_compute_global_forwarding_rule" "http" {
  name        = "${local.name_prefix}-http-fwd"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.app.id
  ip_address  = google_compute_global_address.app.address
}
