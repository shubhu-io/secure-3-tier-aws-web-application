# Observability & Monitoring Screenshots

This folder contains verification screenshots for AWS CloudWatch metrics, dashboards, and automated alerting services configured in `ap-south-1`.

---

## 📋 Recommended Captures

| Filename | Description | Context |
|---|---|---|
| `01-cloudwatch-dashboard.png` | Unified dashboard showing EC2 CPU, RDS connections, and ALB HTTP 2xx/5xx rates | Operational Dashboard |
| `02-cloudwatch-alarms.png` | Active alarm inventory verifying automated thresholds (CPU > 70%, DB storage, 5xx rate) | Proactive Alerting |
| `03-sns-subscription.png` | Amazon SNS console displaying confirmed email and operational notification endpoints | Incident Notification |

Refer to [`docs/operations/monitoring.md`](../../docs/operations/monitoring.md) for alarm thresholds and dashboard JSON templates.

---

## 🖼️ Live Verification Preview

### AWS CloudWatch Unified Dashboard (`ap-south-1`)
![CloudWatch Dashboard](./01-cloudwatch-dashboard.png)
