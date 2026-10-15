# EC2 Runbook — Zero to Live, Every Step With Its Errors

> Full operator manual for running this platform on EC2 in `ap-south-1`.
> Each step: **goal → commands → expected output → errors table**.
> General fault-finding lives in [`troubleshooting.md`](./troubleshooting.md) —
> this file is the ordered path; that file is the encyclopedia.

Conventions: `<region>` = `ap-south-1`, `<env>` = `dev`, project = `secure-ntier`.
All repo-relative paths assume repo root as working directory unless stated.

---

## Step 0 — Prerequisites (laptop, one time)

**Goal:** tools present, cost understood (~$0.05–0.10/hr dev while running).

```bash
aws --version        # AWS CLI v2
terraform version    # >= 1.9
docker --version && docker compose version
jq --version
git --version
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 0.1 | `aws: command not found` | Install AWS CLI v2 ([docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)), restart shell |
| 0.2 | `terraform: command not found` / version < 1.9 | Install from [terraform.io](https://developer.hashicorp.com/terraform/install); v1.9+ required by `terraform/versions.tf` |
| 0.3 | `docker: command not found` | Install Docker Desktop (Windows/Mac) or `docker.io` (Linux); EC2-side Docker is installed by user-data, this is only for local builds |

---

## Step 1 — AWS account prep (one time)

**Goal:** admin identity, MFA, billing guardrail.

1. Root: enable MFA, create IAM admin user, `aws configure` (region `ap-south-1`).
2. Billing → create $5 budget alarm to your email.

```bash
aws sts get-caller-identity   # must print your ARN, not an error
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 1.1 | `Unable to locate credentials` / `No valid credential sources` | `aws configure` never ran → run it; or wrong profile → `export AWS_PROFILE=<name>`; verify with `aws configure list`. See `troubleshooting.md` §3 |
| 1.2 | `AccessDenied` on later steps | User lacks permissions → start learning with `AdministratorAccess`, tighten later. See `troubleshooting.md` §2 |

---

## Step 2 — Clone & configure (per environment)

**Goal:** `terraform.tfvars` + `backend.hcl` filled with YOUR values.

```bash
git clone <your-repo-url> && cd secure-ntier-cloud-platform
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
# edit: notification_email (YOUR email), bucket names, domain_name
```

Edit `terraform/environments/dev/terraform.tfvars`:
- `notification_email = "you@example.com"` ← alarms go here; you must click the confirm link AWS emails you (Step 7).
- `domain_name = ""` for plain HTTP dev; set `"app.example.com"` for HTTPS (needs a Route 53 public zone of the same name in the account).
- Keep `nat_gateway_count = 1` (dev). **Do not set 0** — private instances need NAT for apt/ECR/Secrets/SSM.

Edit `terraform/environments/dev/backend.hcl`: set `bucket` to YOUR globally-unique bucket (created in Step 3).

| # | Error | Cause → Fix |
|---|-------|-------------|
| 2.1 | `terraform.tfvars` committed with secrets | Never commit it (gitignored) → `git rm --cached terraform/environments/dev/terraform.tfvars` |
| 2.2 | Bucket name taken | S3 names are global → pick another, update `backend.hcl` |
| 2.3 | `nat_gateway_count = 0` to "save money" | Breaks EVERYTHING on boot (apt, ECR login, Secrets, SSM all need egress) → keep ≥ 1 |

---

## Step 3 — Bootstrap remote state (one time per region)

**Goal:** S3 bucket (versioned, private) + DynamoDB `terraform-locks` table.

```bash
bash terraform/scripts/bootstrap-state.sh ap-south-1 my-org-terraform-state-dev
```

Expected tail: `>>> Done. Update the bucket in environments/{dev,prod}/backend.hcl`.

| # | Error | Cause → Fix |
|---|-------|-------------|
| 3.1 | `BucketAlreadyExists` (not `BucketAlreadyOwnedByYou`) | Name taken globally → rerun with another name, update `backend.hcl` |
| 3.2 | `AccessDenied` on `create-bucket`/`create-table` | IAM lacks S3/Dynamo perms → grant or use admin for bootstrap |
| 3.3 | Skipped because "already exists" from a previous half-run | Safe to rerun — script is idempotent, then continue |

---

## Step 4 — `terraform init`

**Goal:** backend + providers installed.

```bash
cd terraform
terraform init -backend-config="environments/dev/backend.hcl"
```

Expected tail: `Terraform has been successfully initialized!`

| # | Error | Cause → Fix |
|---|-------|-------------|
| 4.1 | `Failed to get existing workspaces: S3 bucket does not exist` | Step 3 not done or wrong bucket in `backend.hcl` → fix name, rerun Step 3 |
| 4.2 | `Error acquiring the state lock` | Another apply running or crashed run left a lock → wait; only if certain it's stale → `terraform force-unlock <LOCK_ID>`. See `troubleshooting.md` §19 |
| 4.3 | Provider install fails | No network/proxy → retry; check `versions.tf` constraints |

---

## Step 5 — `terraform plan` (read it, don't skip)

**Goal:** confirm ~30 resources: VPC/6 subnets/NAT/IGW, SGs, ALB (+WAF only if `enable_waf=true`), ECR ×2, RDS, ASG+LT, SSM params (images + credentials), SNS+9 alarms+dashboard, log groups, CloudTrail.

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 5.1 | `Error: Invalid value for variable` (e.g. email, CIDRs) | Typo in `terraform.tfvars` → fix; CIDRs must not overlap |
| 5.2 | Plan wants to destroy on a re-run | You changed a force-replacement field, or SSM image params show diff → image params have `ignore_changes=[value]` (`compute/main.tf`); anything else being replaced deserves a second look before `apply` |
| 5.3 | `data.aws_route53_zone` error with `domain_name` set | Zone must exist as public hosted zone in the account → create it or leave `domain_name = ""` |

---

## Step 6 — `terraform apply` (infra goes live, app stays red — expected)

**Goal:** full AWS skeleton. Takes 15–25 min (RDS is slow).

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

Expected: `Apply complete!`, outputs include `app_url` (ALB DNS).
`curl http://<ALB_DNS>/health` now → **503** (no healthy targets). **This is normal.**

What happens on first boot (know this or Step 6 looks broken):
- ASG launches instances → `user-data.sh` installs Docker/compose/AWS CLI, logs in to ECR, validates the secret, then reads SSM `*-image` = `"pending"` → **fails fast**: `ERROR: no image published yet … Run the deploy pipeline first` in `/var/log/user-data.log`. Instances stay unhealthy until Step 8.

| # | Error | Cause → Fix |
|---|-------|-------------|
| 6.1 | Apply fails on RDS (`InvalidParameterCombination`, AZ capacity) | `db.t3.micro` constrained in an AZ → retry (another AZ), or bump `aws_db_instance_class` |
| 6.2 | `InsufficientInstanceCapacity` for `t3.micro` | AZ out of capacity → uncomment `azs` with different AZs, or try `t3.small` |
| 6.3 | Quota `VPC limit / EIP limit exceeded` | New account limits → request increase in Service Quotas, or destroy the other env |
| 6.4 | ACM `PENDING_VALIDATION` forever | DNS validation record not resolving → zone must be public + NS delegated at registrar; or stay HTTP (`domain_name = ""`). See `troubleshooting.md` §17–18 |
| 6.5 | Instances fail ELB checks immediately, log shows apt/ECR errors | NAT missing/blocked or SG egress closed → confirm `nat_gateway_count ≥ 1`, app SG egress `0.0.0.0/0`. See `troubleshooting.md` §11 |
| 6.6 | `aws: command not found` in user-data log | Old launch template from before the fix → `terraform apply` again to pick up current `user-data.sh`, then refresh the ASG |
| 6.7 | `secret … missing required key '…'` in user-data log | Secret JSON lacks a key (hand-created secret?) → secret must contain exactly `username,password,host,port,dbname,jwt_secret` (created by the database module); don't hand-edit it |

---

## Step 7 — Confirm the SNS subscription

**Goal:** alarms can reach a human. AWS emails `notification_email` a confirm link after apply — click it. Unconfirmed = silent alarms.

```bash
aws sns list-subscriptions --region ap-south-1 \
  --query 'Subscriptions[?contains(TopicArn,`secure-ntier-dev`)].{ARN:SubscriptionArn,Confirmed:ConfirmationWasAuthenticated}'
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 7.1 | No email arrived | Wrong `notification_email`, or in spam → fix var, `apply`, confirm |
| 7.2 | `PendingConfirmation` | Link not clicked → click it, rerun check |

---

## Step 8 — Publish images to ECR

**Goal:** backend+frontend images in ECR, tagged `:sha` + `:latest`.

```bash
bash cicd/scripts/ecr-login.sh ap-south-1
bash cicd/scripts/stack-ci.sh            # tests + Trivy locally first (no AWS)
TAG=$(git rev-parse --short HEAD)
bash cicd/scripts/stack-push.sh $TAG ap-south-1 secure-ntier dev
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 8.1 | `stack-ci.sh` fails on tests | Read which service failed → fix code, never `--skip` tests to "get it deployed" |
| 8.2 | Trivy `CRITICAL,HIGH` → exit 1 | Real CVEs in the image → `apk upgrade` is already in Dockerfiles; bump the base image pin (`node:22-alpine`, `nginx:1.29-alpine`) and rebuild |
| 8.3 | `denied: … not authorized` on push | CI identity lacks ECR push → attach `…-cicd-policy` (terraform output `cicd_policy_arn`); check region/account in URI. See `troubleshooting.md` §12 |
| 8.4 | `ecr-login.sh: command not found / no such file` | Run from repo root; filename is `ecr-login.sh` (login), not `registry-login.sh` (used inside Jenkins with multi-cloud wrapper) |

---

## Step 9 — Deploy to the fleet (SSM pointer + rolling refresh)

**Goal:** new instances boot the exact tested images.

```bash
bash cicd/scripts/deploy-ec2.sh $TAG ap-south-1 dev secure-ntier
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name secure-ntier-dev-asg --region ap-south-1 \
  --query 'InstanceRefreshes[0].{Status:Status,Reason:StatusReason}'
```

Expected: refresh `InProgress` → `Successful` (2–6 min). Then:

```bash
ALB_URL="http://<ALB_DNS>" ATTEMPTS=36 bash cicd/scripts/smoke-test.sh
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 9.1 | `ssm put-parameter AccessDenied` | Missing `ssm:PutParameter` on `/*/backend-image,/*/frontend-image` → attach cicd policy |
| 9.2 | Refresh `Failed`/`Cancelled`, `MinHealthy` reason | New instances never healthy → Session-Manager in (`aws ssm start-session --target <id>`), read `/var/log/user-data.log` + `docker compose -f /opt/app/docker-compose.yml logs`. Common: DB still creating (wait, `initDb` retries 12×10s), wrong image URI in SSM (`aws ssm get-parameter --name /secure-ntier/dev/backend-image`). See `troubleshooting.md` §20–21 |
| 9.3 | Refresh `Successful` but app still old version | SSM param updated but refresh pointed at old launch template, or you checked before warmup → verify param value = new SHA, wait out `InstanceWarmup:120s` |
| 9.4 | Smoke test times out | Targets still registering → `describe-target-health`; if `unhealthy`, curl `:80/health` on the instance; check backend `docker logs` for `ECONNREFUSED` (DB SG/secret host). See `troubleshooting.md` §5–6, §9–10 |

---

## Step 10 — Verify end-to-end (do all of these)

```bash
curl -s http://<ALB_DNS>/health            # {"status":"ok","db":"connected",...}
curl -s http://<ALB_DNS>/health/ready      # {"status":"ready",...} (strict)
curl -s http://<ALB_DNS>/metrics | head    # Prometheus counters (internal too)
# UI: open http://<ALB_DNS> → register → login → create/list/delete item
aws cloudwatch describe-alarms --region ap-south-1 \
  --query "MetricAlarms[?contains(AlarmName,'secure-ntier-dev')].{Alarm:AlarmName,State:StateValue}" --output table
aws elbv2 describe-target-health --target-group-arn <tg-arn> --region ap-south-1
```

| # | Symptom | Cause → Fix |
|---|---------|-------------|
| 10.1 | `/health` 200 but `db: disconnected`, API 503s | Backend can't reach RDS → secret host wrong / DB SG closed / RDS still `creating` (`describe-db-instances` → wait for `available`; init retries cover ~2 min, longer waits need a refresh). See `troubleshooting.md` §9–10 |
| 10.2 | `/health/ready` 503 while `/health` 200 | By design (`health.js`): liveness vs readiness → fix the DB, not the probe |
| 10.3 | WAF 403 on legit requests (only when `enable_waf=true`; off by default) | Managed rules false-positive → check WAF sampled requests, add scoped allow rule; keep block on real payloads. See `troubleshooting.md` §8 |
| 10.4 | Alarms `INSUFFICIENT_DATA` | Fresh resources, no metrics yet → wait 10–15 min; if a resource was deliberately stopped, silence its alarm so the board stays honest |
| 10.5 | Frontend loads, `/api/*` 502 | nginx→backend break → both must be in `/opt/app/docker-compose.yml` on the same network (user-data generates this); `wget -qO- http://backend:3000/health` from the frontend container. See `troubleshooting.md` §15 |

---

## Step 11 — Operate (day 2 and on)

- **Redeploy:** repeat Steps 8–9 with the new SHA (or `git push` to `main` and let Jenkins do it). Zero-downtime via 50% MinHealthy rolling refresh.
- **Rollback:** `bash cicd/scripts/deploy-ec2.sh <old-sha> ap-south-1 dev secure-ntier` → refresh rolls back to the known-good image.
- **Scale:** change `asg_*` in `terraform.tfvars` → `apply` (no redeploy needed).
- **Secrets:** rotate in the SSM parameter `/secure-ntier-<env>/db-credentials` (same 6 JSON keys) → instance refresh so containers re-read them.
- **Logs:** CloudWatch `/secure-ntier-dev/app` (Insights queries in `monitoring/logs/patterns.md`); instance boot: `/var/log/user-data.log`; containers: `docker compose -f /opt/app/docker-compose.yml logs`.
- **Monitoring overlay (optional):** `docker-compose.monitoring.yml` (Prometheus/Grafana/Loki/Blackbox) is local-first; EC2 roll-out is tracked in `docs/architecture/monitoring.md`.

---

## Step 12 — Destroy (stop the billing)

```bash
cd terraform
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

| # | Error | Cause → Fix |
|---|-------|-------------|
| 12.1 | Destroy hangs on S3/buckets | `force_destroy` is set on created buckets; if you added objects with retention, empty first |
| 12.2 | `deletion_protection` blocks RDS/ALB | Only set in prod; for dev it's `false` — if you enabled it, disable → `apply` → `destroy` |
| 12.3 | State lock during destroy | Same as 4.2 → `force-unlock` only when certain |

---

## Master error index (where each failure is explained)

| Area | Sections above | Deep dive |
|------|---------------|-----------|
| Credentials/IAM/state | 1.1–1.2, 3.2, 4.1–4.2, 12.3 | `troubleshooting.md` §1–3, §19 |
| Networking/ALB/SG/DNS/TLS | 2.3, 5.3, 6.4–6.5, 10.3, 10.5 | `troubleshooting.md` §4–6, §8, §15, §17–18 |
| Boot/user-data/containers | 6.6–6.7, 9.2 | `troubleshooting.md` §7, §11; user-data log `/var/log/user-data.log` |
| ECR/IAM deploy | 8.3–8.4, 9.1 | `troubleshooting.md` §12–14 |
| Refresh/rollout/smoke | 9.2–9.4 | `troubleshooting.md` §20–22 |
| DB/RDS | 10.1–10.2 | `troubleshooting.md` §9–10 |
| Alarms | 7.1–7.2, 10.4 | `monitoring/alarms/README.md`, `docs/operations/monitoring.md` |
