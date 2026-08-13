# ============================================================================
# Monitoring module - SNS + CloudWatch alarms + dashboard
#
#   Metric ──▶ CloudWatch Alarm ──▶ SNS Topic ──▶ Email to ops
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  # ALB/TG resource names appear as dimension values (suffix after arn:aws:...)
  alb_suffix = join("/", slice(split("/", var.alb_arn), 2, length(split("/", var.alb_arn))))
  tg_suffix  = join("/", slice(split("/", var.target_group_arn), 2, length(split("/", var.target_group_arn))))
}

# ---------------------------------------------------------------------------
# SNS topic + subscription
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---------------------------------------------------------------------------
# EC2 / ASG alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name                = "${local.name_prefix}-asg-cpu-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.cpu_high_threshold
  alarm_description         = "Average CPU of the ASG above ${var.cpu_high_threshold}% for 10 minutes"
  treat_missing_data        = "notBreaching"
  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# ---------------------------------------------------------------------------
# ALB alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "${local.name_prefix}-alb-target-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "Target 5xx responses above ${var.alb_5xx_threshold} in 10 minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "At least one target is unhealthy"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
}

# ---------------------------------------------------------------------------
# RDS alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "RDS CPU above ${var.rds_cpu_threshold}% for 10 minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  # 20% of allocated storage, in bytes
  threshold          = var.db_allocated_storage_gb * 1024 * 1024 * 1024 * 0.2
  alarm_description  = "RDS free storage below 20% of allocated size"
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# ---------------------------------------------------------------------------
# Overview dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", { "stat" = "Average" }],
            ["AWS/RDS", "CPUUtilization", { "stat" = "Average" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB requests and errors"
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { "stat" = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Healthy hosts"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { "stat" = "Average" }]
          ]
        }
      },
      {
        type   = "text"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          markdown = "### ${local.name_prefix}\n\n**Metric → Alarm → SNS → Email**\n\nAlarms fire when:\n- ASG CPU > ${var.cpu_high_threshold}%\n- ALB target 5xx > ${var.alb_5xx_threshold}\n- A target is unhealthy\n- RDS CPU > ${var.rds_cpu_threshold}%\n- RDS free storage < 20%"
        }
      }
    ]
  })
}
