# ============================================================================
# Monitoring module - notification channel + alert policies + dashboard
# ----------------------------------------------------------------------------
#   Metric -> Alert Policy -> Notification Channel (email) -> ops
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Notification channel (email)
# ---------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
  display_name = "${local.name_prefix}-email"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

# ---------------------------------------------------------------------------
# Alert: ASG/MIG CPU high
# ---------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "cpu_high" {
  display_name = "${local.name_prefix}-cpu-high"
  combiner     = "OR"

  conditions {
    display_name = "CPU > 70%"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.label.instance_group_manager = \"${var.asg_name}\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.7

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# ---------------------------------------------------------------------------
# Alert: HTTP 5xx on the load balancer
# ---------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "http_5xx" {
  display_name = "${local.name_prefix}-http-5xx"
  combiner     = "OR"

  conditions {
    display_name = "HTTP 5xx responses"

    condition_threshold {
      filter          = "resource.type = \"https_lb_rule\" AND metric.type = \"loadbalancing.googleapis.com/https/request_count\" AND metric.label.response_code_class = \"500\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# ---------------------------------------------------------------------------
# Overview dashboard
# ---------------------------------------------------------------------------
resource "google_monitoring_dashboard" "overview" {
  dashboard_json = jsonencode({
    displayName = "${local.name_prefix}-overview"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "CPU utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                }
              }
            }]
          }
        },
        {
          title = "HTTP requests (LB)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}
