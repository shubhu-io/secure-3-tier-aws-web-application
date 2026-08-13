# Operations — Monitoring

## Where to look

| Concern | Tool |
| ------- | ---- |
| Live metrics (CPU, requests, hosts) | CloudWatch dashboard `secure-ntier-<env>-overview` |
| App logs | CloudWatch Logs → log group `/secure-ntier-<env>/app` |
| Network traffic | VPC Flow Logs → `/aws/vpc-flow-log/<project>-<env>` |
| Alarm state | CloudWatch → Alarms (or the SNS emails you receive) |
| Who did what | CloudTrail → Event history |

## Dashboard

Open the AWS Console → CloudWatch → Dashboards → `secure-ntier-dev-overview`.
You should see CPU, ALB requests/errors, and healthy hosts.

## Alarms at a glance

```bash
aws cloudwatch describe-alarms --region <region> \
  --query "MetricAlarms[?contains(AlarmName, 'secure-ntier-dev')].{Alarm:AlarmName,State:StateValue}" \
  --output table
```

States: `OK` (fine), `ALARM` (breach), `INSUFFICIENT_DATA` (not enough data —
often right after creation or when resources are stopped).

## Log queries

Open CloudWatch → Logs Insights → select the log group. Ready-made queries:
[`monitoring/logs/patterns.md`](../../monitoring/logs/patterns.md).

## Diagnosing a reported incident

1. **Alarm fired?** → which one? That tells you the layer (app/ALB/RDS).
2. **App logs** — search for `error`/`Fatal`.
3. **Target health** — `aws elbv2 describe-target-health --target-group-arn <tg>`.
4. **Instance status** — `aws ec2 describe-instance-status --region <region>`.
5. **Flow logs** — check `REJECT` entries.

## Escalation

- Follow the matching runbook in [`docs/runbooks/`](../runbooks/).
- If recovery actions are unclear or risky, escalate to the platform team.

## Keep the dashboard honest

Alarms with `INSUFFICIENT_DATA` are not monitoring anything. If a resource is
stopped intentionally (e.g. dev ASG scaled to 0), silence or delete its
alarms so the signal stays meaningful.
