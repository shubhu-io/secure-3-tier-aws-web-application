# Alarms

All alarms are created by the Terraform `monitoring` module
(`terraform/modules/monitoring/main.tf`). This file is a reference of what
exists and what each one means.

| Alarm | Metric | Condition | Why it matters |
| ----- | ------ | --------- | -------------- |
| `<project>-<env>-asg-cpu-high` | `AWS/EC2 CPUUtilization` (ASG) | Avg > 70% for 2×5min | Instances are overloaded; ASG target tracking should already be scaling |
| `<project>-<env>-alb-target-5xx` | `AWS/ApplicationELB HTTPCode_Target_5XX_Count` | Sum > 10 per 5min | Application errors reaching users |
| `<project>-<env>-alb-unhealthy-hosts` | `UnHealthyHostCount` | ≥ 1 for 3×1min | Instances are failing health checks |
| `<project>-<env>-rds-cpu-high` | `AWS/RDS CPUUtilization` | Avg > 80% for 2×5min | Database is the bottleneck |
| `<project>-<env>-rds-storage-low` | `FreeStorageSpace` | < 20% of allocated | Storage autoscaling can only help so much |

## Alert path

```text
CloudWatch Metric
   ↓
Metric Alarm (threshold breach)
   ↓
SNS Topic (<project>-<env>-alerts)
   ↓
Email subscription (ops@example.com)
```

## Adding your own

The module accepts new alarm resources easily — copy the pattern:

```hcl
resource "aws_cloudwatch_metric_alarm" "custom" {
  alarm_name          = "${local.name_prefix}-custom"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "YourMetric"
  namespace           = "Your/Namespace"
  period              = "300"
  statistic           = "Average"
  threshold           = 50
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { ... }
}
```
