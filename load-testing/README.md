# Load Testing

Traffic generators that prove the platform behaves under real load and that
autoscaling actually triggers. Pairs with the "Load spike" failure test in
[`docs/runbooks/`](../docs/runbooks/) and the ASG CPU>70% alarm.

| File | Purpose |
| ---- | ------- |
| `smoke.js` | 1 VU / 30s deploy gate: `/health` returns `db: connected`, p95 < 800ms |
| `stress.js` | Ramping arrival rate up to ~400 req/s: drives ASG scale-out + HPA |
| `run.sh` | Runner wrapper - uses k6 if present, falls back to a hey burst |

## Run against a deployment

```bash
# local compose stack
./load-testing/run.sh http://localhost smoke

# deployed ALB
./load-testing/run.sh https://my-alb-123.ap-south-1.elb.amazonaws.com stress
```

## While the stress test runs, watch

1. **CloudWatch** - ASG CPU crosses 70%, scale-out alarm fires.
2. **ASG activity** - new instance launches and joins the target group.
3. **k6 thresholds** - error rate stays under 5% during scale-up.
4. **Scale back** - after load drops, ASG scales in (cooldown applies).

## Install tooling

```bash
# k6 (preferred)
brew install k6            # macOS
choco install k6           # Windows
docker run --rm -i grafana/k6 run - <load-testing/smoke.js   # no install

# hey (fallback)
go install github.com/rakyll/hey@latest
```

## Rules of thumb

- Only point `stress.js` at disposable environments - it is designed to
  generate billable load and CPU.
- Keep thresholds honest: if p95 creeps above budget, tune DB queries or
  add replicas before raising the limit.
