# Chaos Experiments

Scripted versions of the failure tests described in the README and
[`docs/runbooks/`](../docs/runbooks/). Each experiment injects one controlled
failure so you can watch the platform self-heal - autoscaling replace
instances, health checks drain bad targets, alarms page you.

> **Dev environments only.** Every script is a dry run by default; add
> `--yes` to actually execute.

| Script | Failure injected | Expected recovery | Runbook |
| ------ | ---------------- | ----------------- | ------- |
| `kill-instance.sh` | One app instance terminated | ASG launches replacement in 2-5 min; ALB keeps serving | `instance-failure.md` |
| `stop-container.sh` | backend container stopped via SSM | ALB drains target, compose restarts it, target returns healthy | `instance-failure.md` |
| `az-failure.sh` | All instances in one AZ terminated | Other AZ serves traffic; ASG rebalances across AZs | `deployment-failure.md` |
| `db-outage.sh` | RDS reboot (~60s unavailability) | `/health` shows `db: disconnected`, no crash-loop, auto-reconnect | `database-failure.md` |

## Example session

```bash
export AWS_REGION=ap-south-1

# terminal 1: keep an eye on the public endpoint
watch -n5 'curl -s https://<alb>/health'

# terminal 2: run the experiment
./chaos/kill-instance.sh --project secure-ntier --env dev --yes

# watch the fleet heal:
aws autoscaling describe-auto-scaling-groups --region ap-south-1 \
  --query 'AutoScalingGroups[].Instances[].{id:InstanceId,h:HealthStatus,l:LifecycleState}'
```

## What "pass" looks like

- Zero (or single-digit seconds of) failed requests on surviving capacity.
- Alarms fired where expected (unhealthy host count) and resolved.
- Fleet returns to full desired capacity without manual action.
- Notes captured into the matching runbook for future reference.
