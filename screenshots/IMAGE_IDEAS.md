# Image Ideas — Screenshot Planning Guide

> You generate images; I will place them in the folders below — *jaha jarurat hai waha add kar dunga*.
> All images should be PNG < 500 KB, named as `NN-kebab-case.png` per folder.
> Never claim a diagram render as a real console screenshot — mark `Diagram:` vs `Screenshot:`.
> **Note: Everything runs on AWS EC2** — so primary screenshots are EC2/ASG/ALB/RDS on EC2. Kubernetes folder is optional (only if `aws_enable_eks=true`).

## Folder Map (where each image goes)

```
screenshots/
├── terraform/   → Terraform on EC2 path (init/plan/apply/destroy, backend, outputs) — PRIMARY
├── jenkins/     → Jenkins on EC2 steps (controller on EC2, pipelines, agents, stages)
├── cicd/        → GitHub Actions EC2 deploy (deploy-ec2.sh → ASG refresh)
├── deployment/  → EC2 verification (ALB → EC2 targets, user-data logs, docker compose on EC2)
├── kubernetes/  → EKS/AKS/GKE — OPTIONAL only if you enable EKS
└── monitoring/  → CloudWatch on EC2 (alarms for ASG CPU, ALB 5xx, etc.)
```

---

## 1. Terraform Steps — `screenshots/terraform/`

| # | Filename idea | What to capture | When in doc |
|---|---------------|-----------------|-------------|
| T01 | `01-terraform-init-backend.png` | `terraform init -backend-config="cloud/aws/backend.hcl"` success | `docs/deployment/terraform.md` Step 1 |
| T02 | `02-terraform-fmt-validate.png` | `terraform fmt -check` + `validate` clean output | same — validation |
| T03 | `03-terraform-plan.png` | `terraform plan -var="cloud=aws" ...` showing ~28 to add | same — plan |
| T04 | `04-terraform-apply-output.png` | `terraform apply` completed + `app_url` output | same — apply |
| T05 | `05-terraform-outputs.png` | `terraform output` list (app_url, db_host, ecr_url) | verification |
| T06 | `06-terraform-destroy.png` | `terraform destroy` confirmation | cleanup section |
| T07 | `07-backend-s3-lock.png` | S3 bucket + DynamoDB lock table in console | `terraform/scripts/bootstrap-state.sh` |
| T08 | `08-multi-cloud-dispatch.png` | `terraform plan -var="cloud=azure"` vs `gcp` diff (optional) | multi-cloud guide |

Generate: terminal captures (dark or light theme, include timestamp). Crop to relevant lines.

---

## 2. Jenkins Steps — `screenshots/jenkins/`

| # | Filename idea | What to capture | Doc location |
|---|---------------|-----------------|--------------|
| J01 | `01-jenkins-provision.png` | `terraform apply` with `enable_jenkins=true` → `jenkins_url` output | `docs/deployment/jenkins.md` Step 1 |
| J02 | `02-jenkins-unlock.png` | Jenkins unlock screen (admin password from SSM `/var/log/jenkins-init.log`) | Step 2 |
| J03 | `03-jenkins-plugins.png` | Suggested plugins install screen | Step 2 |
| J04 | `04-jenkins-credentials-aws.png` | Jenkins → Manage Credentials → AWS keys / GitHub token | Step 3 |
| J05 | `05-jenkins-agent-docker.png` | Agent node labelled `docker` online (executors) | Step 3 |
| J06 | `06-jenkins-ci-pipeline.png` | `secure-ntier-ci` pipeline green run (stages: validate, test, scan, fmt) | Jenkinsfile-ci |
| J07 | `07-jenkins-deploy-pipeline.png` | `secure-ntier-deploy` stages: ecr-login → build → push → ASG refresh → smoke test | Jenkinsfile |
| J08 | `08-jenkins-build-log.png` | Console output snippet of successful build + Trivy scan | - |
| J09 | `09-jenkins-asg-refresh.png` | ASG instance refresh activity triggered by Jenkins | integration proof |

Generate: browser + Jenkins LTS UI, hide secrets. Use `aws ssm start-session` thumb where relevant.

---

## 3. CI/CD (GitHub Actions) — `screenshots/cicd/`

| # | Filename | Idea |
|---|----------|------|
| C01 | `01-actions-ci-green.png` | Actions → `CI` workflow green on PR (validate + build-and-scan) |
| C02 | `02-actions-deploy-green.png` | Actions → `Deploy` workflow green on `main` (push→refresh→smoke) |
| C03 | `03-actions-terraform-plan.png` | `Terraform` workflow PR comment with plan summary |
| C04 | `04-ecr-images-pushed.png` | ECR / ACR / Artifact Registry showing `backend:<tag>` + `frontend:<tag>` |
| C05 | `05-smoke-test-log.png` | Deploy log: `curl /health → {"status":"ok","db":"connected"}` |

---

## 4. Deployment / App Verification — `screenshots/deployment/`

| # | Filename | Idea |
|---|----------|------|
| D01 | `01-alb-targets-healthy.png` | EC2 → Target Groups → Targets: 2× healthy |
| D02 | `02-app-health-json.png` | `curl -s <ALB>/health` → `{"status":"ok","db":"connected"}` (terminal) |
| D03 | `03-app-ui-login.png` | Browser → `http://<ALB>` login screen (React) |
| D04 | `04-app-items-crud.png` | Create/list/delete items via UI or API |
| D05 | `05-rds-private.png` | RDS → Configuration: PubliclyAccessible=false, Encrypted, VPC private |
| D06 | `06-secrets-manager.png` | Secrets Manager → `db-credentials` JSON (redacted) |
| D07 | `07-waf-webacl.png` | WAF → Web ACL rules (managed rule groups) |
| D08 | `08-sg-chain.png` | Security groups: ALB → App (3000) → DB (5432) only |

---

## 5. Kubernetes (Optional) — `screenshots/kubernetes/`

| # | Filename | Idea |
|---|----------|------|
| K01 | `01-eks-cluster.png` | EKS → Clusters → `secure-ntier-dev-eks` Active |
| K02 | `02-kubectl-get-pods.png` | `kubectl -n secure-ntier get pods` → 2× Running |
| K03 | `03-kubectl-get-svc.png` | `kubectl get svc frontend` → LoadBalancer hostname |
| K04 | `04-hpa-pdb.png` | `kubectl get hpa/pdb` |

---

## 6. Monitoring — `screenshots/monitoring/`

| # | Filename | Idea |
|---|----------|------|
| M01 | `01-cloudwatch-alarms.png` | CloudWatch → Alarms → 5+ alarms (ASG CPU, 5xx, unhealthy hosts, RDS) |
| M02 | `02-cloudwatch-dashboard.png` | Dashboard `secure-ntier-*` overview |
| M03 | `03-sns-subscription.png` | SNS → Subscriptions → email confirmed |

---

## Naming & Placement Contract

- **You generate** images following the ideas above — keep raw files, I will rename `NN-...png` if needed.
- **I will place** them: `screenshots/<folder>/NN-...png` and wire `![Screenshot: ...](screenshots/...)` into `README.md` and `docs/deployment/*.md` at the exact step.
- **Placeholders in docs:** each doc already has `> 📸 Screenshot placeholder: screenshots/.../NN-...png` comments — replace `placeholder` with real image once generated.
- **Size:** < 500 KB; if larger, run `pngquant` or export at 1280px wide.
- **Redaction:** blur emails, IPs, account IDs.

## Quick Checklist Before You Generate

- [ ] Run `terraform apply` once (AWS reference) to have real resources to capture
- [ ] Capture terminal with `terraform output` visible
- [ ] Spin one Jenkins run if using Jenkins path
- [ ] Take browser captures at 100% zoom, not zoomed

Once you drop images into any folder, tell me the filenames and I will link them in README + step files automatically.
