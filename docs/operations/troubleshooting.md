# Troubleshooting Guide

Every issue uses the same structure: **Problem → Symptoms → Possible Cause →
Diagnosis → Commands → Fix → Verification → Prevention**.

---

## 1. `terraform init` failed

- **Symptoms:** command exits with an error during "Initializing the backend" or "Installing providers".
- **Possible cause:** missing backend bucket, missing network access, wrong bucket name, or a typo in `backend.hcl`.
- **Diagnosis:** read the error tail — it names the failing step.

```bash
terraform init -backend-config="environments/dev/backend.hcl"
```

- **Fix:** for `Failed to get existing workspaces` → create the S3 bucket + DynamoDB table (see [aws-setup.md](../deployment/aws-setup.md)). For provider install errors → check internet/proxy, retry.
- **Verification:** the output ends with `Terraform has been successfully initialized!`.
- **Prevention:** keep `backend.hcl` per environment and verify the bucket name is globally unique.

## 2. `terraform plan` / `apply` failed with `AccessDenied`

- **Symptoms:** `Error: AccessDenied ... on s3 bucket` or `AccessDeniedException`.
- **Possible cause:** the IAM user lacks S3/DynamoDB/EC2/etc. permissions.
- **Diagnosis:** `aws sts get-caller-identity` (works?) → `aws s3 ls` (works?).

```bash
aws sts get-caller-identity
aws s3 ls
```

- **Fix:** grant the IAM user the required permissions (this project: start with `AdministratorAccess` for learning, then tighten), or fix `aws configure` to use the right profile.
- **Verification:** rerun `terraform plan` — it completes.
- **Prevention:** don't share credentials; keep one identity per tool/person.

## 3. AWS credentials not configured

- **Symptoms:** `No valid credential sources found`, `Unable to locate credentials`.
- **Possible cause:** `aws configure` never run, or profile mismatch.
- **Diagnosis:**

```bash
aws configure list
```

- **Fix:** `aws configure`, or `export AWS_PROFILE=<profile>` / `AWS_ACCESS_KEY_ID=...`.
- **Verification:** `aws sts get-caller-identity` returns your ARN.
- **Prevention:** document which profile each machine uses.

## 4. Security group timeout / app unreachable from browser

- **Symptoms:** connection to the ALB URL hangs/times out; curl fails.
- **Possible cause:** ALB SG doesn't allow the port, ALB in wrong subnets, no healthy targets, or DNS not propagated.
- **Diagnosis:**

```bash
curl -sv http://<ALB_DNS>/health
aws elbv2 describe-target-health --target-group-arn <tg> --region <region>
```

- **Fix:** check `aws_lb_target_group.app` health check path `/health`; confirm ASG registered targets; verify SG ingress 80/443 on the ALB SG and port 80 from ALB SG on the app SG.
- **Verification:** `describe-target-health` shows all `healthy`; curl returns JSON.
- **Prevention:** SG rules are code — review diffs in the plan.

## 5. ALB returns 502 Bad Gateway

- **Symptoms:** browser shows `502`, curl to ALB returns `502`.
- **Possible cause:** target registered but unhealthy, or the app/nginx isn't listening on the target port.
- **Diagnosis:**

```bash
aws elbv2 describe-target-health --target-group-arn <tg> --region <region>
# SSH via Session Manager to an instance and check:
sudo docker compose -f /opt/app/docker-compose.yml ps
curl -s http://localhost/health
```

- **Fix:** if the container isn't running → check logs (`/var/log/user-data.log`, `docker compose logs`). If it's running but 502 → nginx can't reach backend → check nginx config / backend container health.
- **Verification:** target group shows `healthy`; `/health` returns 200.
- **Prevention:** the pipeline's smoke test catches this before anyone else does.

## 6. ALB returns 503 Service Unavailable

- **Symptoms:** `503`, "Service Temporarily Unavailable".
- **Possible cause:** **no healthy targets** — all instances unhealthy or ASG empty.
- **Diagnosis:**

```bash
aws elbv2 describe-target-health --target-group-arn <tg> --region <region>
```

- **Fix:** instances may be booting (first apply with no images yet) → wait or check user-data logs; or the app keeps failing → fix app/image, redeploy, refresh.
- **Verification:** targets healthy; `/health` 200.
- **Prevention:** monitor `UnHealthyHostCount` (an alarm already exists).

## 7. Docker container exits immediately

- **Symptoms:** `docker compose ps` shows `Exit 1` / restart loop.
- **Possible cause:** missing env var (e.g. `JWT_SECRET` empty), DB unreachable at startup, or a code crash.
- **Diagnosis:**

```bash
sudo docker compose -f /opt/app/docker-compose.yml logs backend
sudo journalctl -u docker 2>/dev/null | tail -20
```

- **Fix:** read the stack trace. Typical: `JWT_SECRET must be set` → check the secret was written to Secrets Manager; `ECONNREFUSED` → check DB SG/security group and the `host` value.
- **Verification:** container reports `healthy`; `/health` returns 200.
- **Prevention:** the container has a HEALTHCHECK; the ASG replaces unhealthy instances.

## 8. Application not reachable at all

- **Symptoms:** no HTTP response from ALB URL; DNS resolves but connection refused.
- **Possible cause:** ALB not created/exposed, WAF blocking, or SG issue.
- **Diagnosis:**

```bash
aws elbv2 describe-load-balancers --region <region>
curl -sv http://<ALB_DNS>/health
```

- **Fix:** confirm ALB is `active`; confirm the ALB SG has 80/443 ingress; confirm WAF ACL default action is `allow` (it blocks only matched rules).
- **Verification:** curl returns a health JSON.
- **Prevention:** add a CloudWatch alarm on ALB `RequestCount`.

## 9. Database connection failed / `ECONNREFUSED` to RDS

- **Symptoms:** backend logs show `ECONNREFUSED` / `timeout expired` to the RDS host; `/health` shows `db: "disconnected"`.
- **Possible cause:** wrong host in the secret, DB SG doesn't allow app SG, DB stopped, or credentials wrong.
- **Diagnosis:**

```bash
# from the instance
aws secretsmanager get-secret-value --secret-id <secret> --region <region> --query SecretString --output text
# check RDS is available
aws rds describe-db-instances --region <region> --query 'DBInstances[0].DBInstanceStatus'
```

- **Fix:** confirm the secret host matches `db_host`; confirm `db_sg` allows 5432 from `app_sg`; confirm the DB is in `available` state.
- **Verification:** `/health` shows `db: "connected"`.
- **Prevention:** the DB SG references the app SG by ID (not a CIDR), so a mis-IP'd instance can't connect.

## 10. RDS connection timeout (not refused)

- **Symptoms:** `connect ETIMEDOUT` instead of `ECONNREFUSED`.
- **Possible cause:** the DB subnet route/NACL or the app cannot reach the DB subnet at all.
- **Diagnosis:** check VPC Flow Logs for `REJECT` on port 5432:

```sql
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter dstPort = 5432 and action = "REJECT"
```

- **Fix:** verify NACL `db` allows 5432 from app CIDRs and the app route table routes to the DB subnet via `local`; ensure the app and DB are in the same VPC.
- **Verification:** flow logs stop showing REJECTs; `/health` connected.
- **Prevention:** NACL + SG are both tested by [`tests/security/security-tests.sh`](../../tests/security/security-tests.sh).

## 11. EC2 health check failed

- **Symptoms:** instance shows `2/2 checks failed` in the console; ASG replaces it.
- **Possible cause:** the user-data script errored, Docker not installed, or the container never started.
- **Diagnosis:**

```bash
aws ssm describe-instance-information --region <region>   # is the SSM agent online?
# if online, open a session:
aws ssm start-session --target <instance-id> --region <region>
sudo cat /var/log/user-data.log
```

- **Fix:** read the log; fix the user-data or the image; redeploy.
- **Verification:** new instance boots and passes status checks.
- **Prevention:** the user-data logs everything to `/var/log/user-data.log`; run `bash -x` mentality when editing it.

## 12. ECR authentication failed

- **Symptoms:** `docker login` fails, `denied: Your Authorization Token has expired` during pull.
- **Possible cause:** wrong credentials, wrong region, or the instance role lacks ECR permissions.
- **Diagnosis:**

```bash
# on the instance
aws sts get-caller-identity
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
```

- **Fix:** verify the instance role policy includes `ecr:GetAuthorizationToken` + pull actions; check `aws configure`/role on the machine.
- **Verification:** `docker pull <uri>` succeeds.
- **Prevention:** the instance role policy is least-privilege but includes ECR pull (see compute module).

## 13. CI/CD pipeline failed

- **Symptoms:** GitHub Actions shows a red X; a stage has an error.
- **Possible cause:** test failure, scan finding, or AWS permission issue.
- **Diagnosis:** open the failed step's logs in GitHub Actions.
- **Fix:** address the specific error — common ones: secrets not set, ECR policy missing, ASG name mismatch, smoke test timeout.
- **Verification:** rerun; green pipeline.
- **Prevention:** CI gates (tests + scans) catch most issues before deploy; the smoke test catches deploy issues.

## 14. GitHub webhook / trigger not firing

- **Symptoms:** push to `main` doesn't start the workflow.
- **Possible cause:** workflow file not on `main` yet, wrong branch name, or Actions disabled.
- **Diagnosis:** GitHub → Actions → check the workflow list; check branch protections.
- **Fix:** ensure `.github/workflows/deploy.yml` is on `main`; confirm the trigger branch matches.
- **Verification:** a fresh push starts the workflow.
- **Prevention:** test a PR first so `ci.yml` runs before the first `main` push.

## 15. Nginx `502` from the frontend container

- **Symptoms:** the SPA loads but `/api/...` returns 502.
- **Possible cause:** nginx can't resolve/connect to the `backend` service.
- **Diagnosis:**

```bash
sudo docker compose -f /opt/app/docker-compose.yml exec frontend sh
wget -qO- http://backend:3000/health
```

- **Fix:** ensure both services are on the same compose network; ensure backend is running; the nginx `proxy_pass http://backend:3000` hostname must match the compose service name.
- **Verification:** `/api/health`-style calls return JSON.
- **Prevention:** the local compose stack exercises exactly this path before deploy.

## 16. Port already in use (local dev)

- **Symptoms:** `docker compose up` fails with `port is already allocated`.
- **Possible cause:** another container/process uses 80/5432/3000.
- **Diagnosis:**

```bash
netstat -ano | findstr :3000     # Windows
ss -ltnp | grep :3000            # Linux
```

- **Fix:** stop the conflicting process, or change the published port in `docker-compose.yml` (e.g. `"8080:80"`).
- **Verification:** `docker compose up` succeeds.
- **Prevention:** stop leftover containers (`docker compose down`) before re-running.

## 17. DNS not resolving / wrong IP

- **Symptoms:** your domain doesn't load; curl hits the wrong server.
- **Possible cause:** NS delegation not updated at the registrar, or TTL caching.
- **Diagnosis:**

```bash
dig A <YOUR_DOMAIN> +short
dig NS <YOUR_DOMAIN> +short
```

- **Fix:** update the registrar's nameservers to the Route 53 NS records; wait for TTL.
- **Verification:** `dig A` returns the ALB IP (or the alias resolves).
- **Prevention:** use the Route 53 alias record created by Terraform (no manual IP management).

## 18. HTTPS certificate issue

- **Symptoms:** browser warns "connection is not secure"; ALB listener shows no certificate.
- **Possible cause:** ACM certificate not issued (DNS validation pending), or wrong ARN.
- **Diagnosis:**

```bash
aws acm list-certificates --region <region> --query 'CertificateSummaryList[].{Domain:DomainName,Status:Status}'
```

- **Fix:** wait for validation; ensure the `_<domain>` DNS record exists and the zone is public; re-run `terraform apply` after validation to finish the listener wiring.
- **Verification:** status `ISSUED`; `curl -sI https://<domain>` shows the cert.
- **Prevention:** Terraform creates the validation records automatically when the zone is in the same account.

## 19. State lock error

- **Symptoms:** `Error acquiring the state lock`.
- **Possible cause:** another apply in progress or a crashed run left a lock.
- **Diagnosis:** who is applying? check the SNS/alerts; the lock has a timestamp in the DynamoDB item.
- **Fix:** wait; only if certain nobody is applying → `terraform force-unlock <LOCK_ID>`.
- **Verification:** `terraform plan` runs.
- **Prevention:** always use the shared backend; communicate before long applies.

## 20. ASG doesn't pick up the new image

- **Symptoms:** code changed + pipeline green, but the app still runs the old version.
- **Possible cause:** instance refresh didn't run, or new instances pulled a stale URI.
- **Diagnosis:**

```bash
aws ssm get-parameter --name "/secure-ntier/<env>/backend-image" --region <region>
aws autoscaling describe-instance-refreshes --auto-scaling-group-name <asg> --region <region>
```

- **Fix:** if the parameter is old → rerun the pipeline/deploy script. If refresh failed → check `StatusReason`.
- **Verification:** SSM parameter = new SHA; `/health` served by an instance booted after the refresh.
- **Prevention:** the pipeline updates params *then* refreshes (order matters, and is baked into `deploy-ec2.sh`).

## 21. Instance refresh stuck

- **Symptoms:** refresh shows `Pending`/`InProgress` for a long time, or `MinHealthy` errors.
- **Possible cause:** new instances never become healthy (app/image problem) or the ASG can't launch (subnet/AMI issues).
- **Diagnosis:**

```bash
aws autoscaling describe-instance-refreshes --auto-scaling-group-name <asg> --region <region> --query 'InstanceRefreshes[0].{Status:Status,StatusReason:StatusReason}'
```

- **Fix:** if `InstanceLaunchFailures` → check `aws autoscaling describe-scaling-activities` for the error (e.g. AMI missing, launch template broken). If instances never get healthy → fix the app.
- **Verification:** refresh completes with `Successful`.
- **Prevention:** launch templates and images are tested by CI before refresh.

## 22. `docker compose` inside the instance can't reach Secrets Manager / SSM

- **Symptoms:** `An error occurred (AccessDeniedException) when calling the GetSecretValue operation`.
- **Possible cause:** the instance role lacks `secretsmanager:GetSecretValue` on that secret (or wrong region).
- **Diagnosis:** on the instance run the same command the user-data runs and check the policy ARN attached to the role.
- **Fix:** add the permission to the instance role policy in the compute module; re-apply; refresh.
- **Verification:** `aws secretsmanager get-secret-value --secret-id <arn> --region <region>` returns the JSON from the instance.
- **Prevention:** keep the instance role policy in sync with what user-data needs (review in code).

---

## General approach to any outage

1. **Isolate the layer:** client → DNS → WAF → ALB → target → instance → container → backend → DB.
2. **Check alarms & logs** first (data beats guesses).
3. **Make one change, verify it.** Rerun `terraform plan`/`apply` for infra changes.
4. **Use the runbooks** in [`docs/runbooks/`](../runbooks/) for repeatable incidents.
