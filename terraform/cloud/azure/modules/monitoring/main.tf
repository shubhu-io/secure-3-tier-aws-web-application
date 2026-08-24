# ============================================================================
# Monitoring module (Azure) - action group + metric alerts + dashboard.
#
#   Metric ──▶ Metric Alert ──▶ Action Group (email) ──▶ ops
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Action group (notification target).
# ---------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "this" {
  name                = "${local.name_prefix}-alerts"
  resource_group_name = var.resource_group_name
  location            = "Global"
  short_name          = "alerts"

  email_receiver {
    name          = "ops"
    email_address = var.notification_email
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# VMSS CPU high.
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "vmss_cpu" {
  name                = "${local.name_prefix}-vmss-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.asg_id]
  description         = "VMSS average CPU above 80% for 5 minutes"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------------------------------------------------------------------------
# Application Gateway server errors (5xx).
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "appgw_5xx" {
  name                = "${local.name_prefix}-appgw-5xx"
  resource_group_name = var.resource_group_name
  scopes              = [var.lb_id]
  description         = "Application Gateway server errors above 10 in 5 minutes"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "HttpStatusServerError"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------------------------------------------------------------------------
# Application Gateway unhealthy hosts.
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "appgw_unhealthy" {
  name                = "${local.name_prefix}-appgw-unhealthy"
  resource_group_name = var.resource_group_name
  scopes              = [var.lb_id]
  description         = "At least one backend host is unhealthy"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------------------------------------------------------------------------
# PostgreSQL server CPU high.
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "pg_cpu" {
  name                = "${local.name_prefix}-pg-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.db_id]
  description         = "PostgreSQL CPU above 80% for 5 minutes"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------------------------------------------------------------------------
# Overview dashboard.
# ---------------------------------------------------------------------------
resource "azurerm_portal_dashboard" "overview" {
  name                = "${local.name_prefix}-overview"
  resource_group_name = var.resource_group_name
  location            = var.location
  dashboard_properties = jsonencode({
    schemaVersion = 2
    version       = 1
    pages = [
      {
        name = "Overview"
        widgets = [
          {
            position = { x = 0, y = 0, rowSpan = 4, colSpan = 6 }
            metadata = {
              type    = "Extension/LogAnalytics"
              inputs  = []
              rawData = null
            }
            id = "cpu-widget"
          },
          {
            position = { x = 6, y = 0, rowSpan = 4, colSpan = 6 }
            metadata = {
              type   = "InlineDataFrame"
              inputs = []
              rawData = {
                data = "# ${local.name_prefix}\n\nMetric -> Alert -> Action Group (email)\n\n- VMSS CPU > 80%\n- App Gateway 5xx > 10\n- App Gateway unhealthy hosts > 0\n- PostgreSQL CPU > 80%"
              }
            }
            id = "info-widget"
          }
        ]
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}
