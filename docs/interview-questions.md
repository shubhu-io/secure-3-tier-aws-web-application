# Interview Preparation

Questions grounded in **this repository's implementation** — what was actually
built, how it works, and how you can talk about it in an interview. Organized by
topic. "Real project example" always refers to specific files in this repo.

> Hint for interviews: the **one-sentence project summary** is at the end of
> this file. Practice it until it rolls off the tongue.

---

## 1. AWS

**Q: What is a VPC and what does it contain in this project?**
- *Short:* An isolated virtual network with subnets, route tables, and gateways.
- *Detail:* `terraform/modules/vpc/main.tf` builds `aws_vpc` (10.0.0.0/16), 6
  subnets in 3 tiers, an IGW, 1–2 NAT gateways, route tables, NACLs, and flow
  logs.
- *Project example:* Public subs host ALB+NAT; app subs host EC2; db subs host
  RDS with **no internet route**.

**Q: Why put RDS in private subnets?**
- *Short:* No internet route + SG-only access = database cannot be attacked from
  the internet.
- *Detail:* DB subnet group uses only db subnets; `PubliclyAccessible=false`;
  DB SG allows 5432 only from the app SG; the db route table has no default
  route.
- *Project example:* `terraform/modules/database/main.tf` +
  `modules/security/main.tf`.

**Q: How does the ALB route traffic, and what is a health check?**
- *Short:* The ALB forwards `:443/:80` to a target group; health checks decide
  which targets receive traffic.
- *Detail:* Target group checks `GET /health` expecting `200-299` every 30s;
  unhealthy hosts are detached; healthy ones get traffic.
- *Project example:* `terraform/modules/alb/main.tf`.

**Q: How does auto-scaling work here?**
- *Short:* An ASG keeps 2 instances alive across 2 AZs and replaces failures.
- *Detail:* `health_check_type=ELB` makes the ASG trust ALB health; the launch
  template + user-data self-provision replacements; CPU target-tracking scales
  out at 70%.
- *Project example:* `terraform/modules/compute/main.tf`, `user-data.sh`, and
  the failure diagram `diagrams/failure-flow.png`.

**Q: How is the app deployed to EC2 without SSH?**
- *Short:* CI pushes images, updates an SSM parameter, and starts an ASG
  instance refresh; fresh instances boot with new images via user-data.
- *Detail:* `cicd/scripts/deploy-ec2.sh` = `ssm put-parameter` +
  `autoscaling start-instance-refresh`. `user-data.sh` reads the SSM values +
  db secret from Secrets Manager and runs `docker compose up`.
- *Project example:* exactly those files.

---

## 2. Terraform

**Q: What is Terraform state and why is it remote?**
- *Short:* Terraform's record of created resources; remote (S3) survives
  re-clones and is shared.
- *Detail:* State is encrypted on S3; DynamoDB `terraform-locks` prevents two
  simultaneous applies. State contains secrets (random_password), so it's never
  committed.
- *Project example:* `terraform/backend.tf`, `environments/dev/backend.hcl`.

**Q: Why modules?**
- *Short:* Reusable, reviewable, testable building blocks instead of one giant
  main.tf.
- *Detail:* `terraform/modules/{vpc,security,alb,compute,database,ecr,monitoring}`
  each own one concern with clear variables + outputs.
- *Project example:* the module list itself.

**Q: What's the difference between `terraform plan` and `apply`?**
- *Short:* plan shows a dry-run diff; apply makes it real.
- *Detail:* CI runs `validate` + `plan-check` (`tests/infrastructure/`) to gate
  topology changes; humans read the plan to approve.
- *Project example:* `tests/infrastructure/tfplan-check.sh`.

**Q: How do you handle secrets that Terraform generates?**
- *Short:* `random_password` resources → stored only in Secrets Manager;
  state holds them encrypted in S3, not in git.
- *Detail:* `terraform/modules/database/main.tf` generates the DB password +
  jwt secret and writes them into the secret JSON the app reads at boot.
- *Project example:* `aws_secretsmanager_secret_version`.

---

## 3. Docker

**Q: Why Docker on EC2 instead of installing the app on the host?**
- *Short:* The image tested in CI is byte-for-byte what runs in production.
- *Detail:* user-data installs only Docker; the app ships as images from ECR.
  Multi-stage, non-root images keep the host lean.
- *Project example:* `docker/backend/Dockerfile`, `docker/frontend/Dockerfile`.

**Q: What is a multi-stage build?**
- *Short:* Build in a full image, copy only runtime artifacts into a slim final
  image.
- *Detail:* Backend: `node:20-alpine AS build` → runtime `node:20-alpine` with
  `npm ci --omit=dev` and no dev deps. Frontend: Vite build stage → nginx.
- *Project example:* the two Dockerfiles.

**Q: Why run containers as non-root?**
- *Short:* Shrinks the blast radius if the process is compromised.
- *Detail:* Backend creates `appuser`/`appgroup` and `USER appuser`; nginx image
  runs non-root by default.
- *Project example:* `docker/backend/Dockerfile`.

**Q: How does the app reach the database from a container?**
- *Short:* Environment variables (compose) or the runtime secret from Secrets
  Manager (EC2).
- *Detail:* Local: compose passes `DB_HOST=db`. EC2: user-data writes the
  resolved secret (host/port/name/user/pass) into `/opt/app/docker-compose.yml`.
- *Project example:* `docker/docker-compose.yml`, `user-data.sh`.

---

## 4. Linux & Networking

**Q: How do private instances reach the internet for package installs?**
- *Short:* Through the NAT Gateway, which only permits outbound.
- *Detail:* App route table: `0.0.0.0/0 → nat-gw`. Return traffic flows back
  through the same NAT; no inbound path.
- *Project example:* `terraform/modules/vpc/main.tf` (app route table).

**Q: What does user-data do at first boot?**
- *Short:* Provisions the app host: packages → ECR login → read SSM/Secrets →
  render compose → start with retries.
- *Detail:* `/var/log/user-data.log` shows each step; the loop retries compose
  up to 10× so an empty ECR at first apply still converges.
- *Project example:* `terraform/modules/compute/user-data.sh`.

**Q: Security Group vs NACL?**
- *Short:* SG = stateful, resource-level; NACL = stateless, subnet-level.
- *Detail:* NACLs explicitly allow the return path (ephemeral ports) — that's
  why there are paired inbound/outbound rules per tier.
- *Project example:* NACLs in `modules/vpc/main.tf`.

---

## 5. CI/CD

**Q: Explain the pipeline stages.**
- *Short:* test → scan → build → push → deploy → verify.
- *Detail:* CI (`ci.yml`): tests, frontend build, docker build, trivy, terraform
  validate. CD (`deploy.yml`): tests, ECR push, Trivy gate, SSM pointer update,
  instance refresh, smoke test.
- *Project example:* `.github/workflows/ci.yml`, `deploy.yml` +
  `cicd/scripts/*.sh`.

**Q: How do you guarantee the deployed image is the tested one?**
- *Short:* Same image (tagged `github.sha`) is tested, scanned, pushed, and
  deployed — build once, use everywhere.
- *Detail:* `build-and-push.sh` creates `<image>:<sha>`; `deploy-ec2.sh` points
  SSM at that same tag.
- *Project example:* `cicd/scripts/build-and-push.sh`.

**Q: What is an immutable deployment and a rolling instance refresh?**
- *Short:* Never mutate running instances; replace them with new image versions
  while keeping the fleet up.
- *Detail:* `start-instance-refresh` with `MinHealthyPercentage=50` replaces
  instances one or few at a time. Rollback = re-point SSM to the old tag and
  refresh again.
- *Project example:* `cicd/scripts/deploy-ec2.sh`, `compute/main.tf`.

**Q: How does the pipeline authenticate to AWS?**
- *Short:* An IAM user's keys stored as GitHub secrets, or (upgrade) OIDC.
- *Detail:* `configure-aws-credentials` uses `secrets.AWS_ACCESS_KEY_ID` etc.
  The policy is least-privilege (ECR push, SSM, ASG refresh).
- *Project example:* `deploy.yml`, `security/iam/cicd-policy.json`.

---

## 6. Security

**Q: How is the database protected?** — layers: private subnets, no internet
route, SG (5432 from app SG only), NACL, encryption at rest, no public IP.
(Real files: modules/database + modules/security + modules/vpc.)

**Q: Where are secrets and how are they injected?** — Secrets Manager; read at
boot by the instance role; never in code or Git; state holds the plaintext only
inside encrypted S3. (modules/database + compute/user-data.sh)

**Q: How do you stop secrets leaking via source control?** — `.gitignore`
(`.env`, `*.tfvars`, `*.tfstate*`, `*.pem`), `tfvars.example` files committed,
and a secret scan assertion in `security-tests.sh`.

**Q: Why WAF in front of the app?** — filters SQLi/XSS/bad-bot traffic at the
edge, offloading every app instance and adding time for app patching.
(modules/alb WAF ACL + tests/security SQLi/XSS 403 checks.)

---

## 7. Databases

**Q: How do you recover from DB loss?** — RDS automated backups (7d) +
point-in-time recovery (~5 min RPO); restore to a new instance; point the app
at it by updating the secret's host — no code change.
(docs/architecture/disaster-recovery.md, operations/backup.md)

**Q: Why is the DB in its own subnet tier?** — isolation + failover across two
AZs with the same names; multi-AZ (`true` in prod) gives RPO≈0, automatic
failover.

**Q: `health` vs `health/ready`?** — `/health` always 200 (ALB-friendly, doesn't
flap); `/health/ready` strictly 503 when DB is down (readiness signal).
(src/routes/health.js)

---

## 8. Monitoring

**Q: How are issues detected and escalated?** — metric → CloudWatch alarm →
SNS → email. Alarms: ASG CPU>70%, ALB 5xx, unhealthy host >0, RDS CPU, RDS
storage <20%. (modules/monitoring/main.tf)

**Q: Name the 3 log sources.** — CloudTrail (management API), VPC Flow Logs
(network), application logs via `awslogs` driver to CloudWatch.
(terraform/main.tf, modules/vpc, compute/user-data.sh)

---

## 9. SRE & Troubleshooting

**Q: Walk me through an instance failure.** — ALB marks target unhealthy → ASG
(health=ELB) launches a replacement from the launch template → user-data boots
the Docker stack → ALB re-marks healthy. (diagrams/failure-flow.png)

**Q: What are RTO and RPO in this project?** — RTO < 60 min (Terraform state +
ECR rebuild); RPO ~5 min (RDS point-in-time recovery).

**Q: How would you debug ALB 502/503?** — 503 = no healthy targets (check
`describe-target-health` + instance user-data log); 502 = targets up but app
error (check container + backend logs, target port/SG).

---

## 10. System design

**Q: Why this architecture at all?** — The requirement is a multi-tenant web
app that must be resilient, secure, and deployable by non-experts. n-tier VPC +
ASG + ALB + managed RDS gives: zone redundancy, auto-healing, TLS/WAF at the
edge, DB hidden from the internet, and code-driven infrastructure. Everything
is the smallest design that still meets those.

**Q: What would you add in production?** — OIDC for CI, multi-AZ on,
deletion-protection, GuardDuty/Config, OpenSearch log analytics, blue/green or
canary deploys, HTTPS+WAF at the EKS edge, IRSA/External Secrets, and a second
region for DR. (EKS is already in the repo as an optional path - `enable_eks`.)

---

## 11. Kubernetes

**Q: Why EKS instead of just EC2 + Docker Compose?** — Compose gives you a
fixed set of containers on one host; Kubernetes gives declarative desired
state, rolling updates, self-healing (liveness/readiness probes), pod-level
autoscaling (HPA) and a real rollback primitive (`kubectl rollout undo`). For
this project EKS is an **optional coexisting path**, enabled with `enable_eks`.

**Q: How does the app reach the private RDS from a pod?** — The node group runs
in the private app subnets. The EKS cluster security group is added as a source
to the DB security group on 5432, so pods reach RDS through the node ENIs -
RDS is never public.

**Q: How do you avoid secrets in Git / in image layers?** — `deploy.sh` reads
the DB credentials + JWT secret from AWS Secrets Manager at deploy time and
materialises them into a Kubernetes Secret (`app-db-secret`) that the backend
Deployment loads via `secretRef`. Nothing secret is committed. Production
upgrade: IRSA / External Secrets Operator.

**Q: What's the difference between a Deployment, Service and HPA?** — A
Deployment is the declarative desired state (replicas, image, probes). A
Service is a stable network endpoint that load-balances to pods (ClusterIP
internally, LoadBalancer for the public NLB). An HPA watches CPU (or custom
metrics) and changes the replica count.

**Q: How does a rolling update + rollback work?** — `kubectl set image` triggers
a RollingUpdate (maxUnavailable 0, maxSurge 1) that swaps pods one at a time
using the readiness probe. If the new revision is bad, `kubectl rollout undo
deployment/backend` re-points to the previous revision.

**Q: What is a PodDisruptionBudget?** — A policy that caps how many pods can be
voluntarily evicted during node drains / cluster upgrades. Here `minAvailable:
1` guarantees the backend never drops to zero during maintenance.

---

## Company summaries

### "Explain this project in 30 seconds"
> "I built a production-style three-tier web platform on AWS — React frontend,
> Node/API, and PostgreSQL — deployed entirely with code. Terraform creates a
> VPC with public, application, and database tiers; an ALB with WAF fronts two
> EC2 instances in an auto-scaling group; the database is private and encrypted
> with credentials in Secrets Manager. A GitHub Actions pipeline tests, scans,
> builds, and ships Docker images to ECR, then rolls out to new instances with
> a smoke test. CloudWatch alarms page the team. I proved resilience by killing
> an instance and watching the ASG replace it."

### "Explain this project in 2 minutes"
> Add: network design (6 subnets, 3 tiers ×2 AZs; NAT for outbound only; NACLs
> per tier), the deploy mechanism (SSM pointer + instance refresh = immutable
> deploys), security claims (WAF managed rules labeled SQLi/XSS, DB SG only from
> app SG, IMDSv2, no SSH — SSM Session Manager), and operations (CloudTrail,
> flow logs, 5 alarms to SNS, runbooks, DR with RTO<60min / RPO~5min).

### "Explain this project in 5 minutes"
> Walk through the 30 phases (docs/phases.md) top-down: state backend → network
> → security groups → ECR → app/Docker → ALB → EC2/ASG → RDS+Secrets → HTTPS/DNS
> → WAF → CI/CD → monitoring → logging → security/chaos tests → DR → docs.
> Mention the testing matrix (unit to chaos), the cost guide (dev ~$100–140/mo,
> destroy when done), and the future improvements you'd prioritize.

### "Explain the architecture to an interviewer"
> Draw the n-tier diagram (diagrams/architecture.png). Label each tier, its
> threat model, and its controls:
> - **Public:** Internet → Route 53 → WAF → ALB (TLS). Only these ports open.
> - **App:** private, outbound-only via NAT, ASG-managed, self-healing,
>   credential-less (role + Secrets Manager).
> - **Data:** RDS, encrypted, no internet route, SG-locked to the app tier.
> Then describe the CI/CD path and how a commit becomes a verified release, and
> how an instance failure is healed in minutes without human action.