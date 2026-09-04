# EC2 Quick-Start Deployment Guide

> **Goal:** Deploy the full secure-ntier stack on AWS EC2 (ALB → ASG → RDS) using Terraform + Docker.
> No EKS, no Kubernetes — just EC2 instances running Docker Compose, exactly like production.

---

## Prerequisites

| Tool | Min Version | Install |
|---|---|---|
| AWS CLI | v2 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Terraform | ≥ 1.5.0 | [terraform.io](https://developer.hashicorp.com/terraform/install) |
| Docker | ≥ 24 | [docker.com](https://docs.docker.com/get-docker/) |
| jq | any | `apt install jq` / `brew install jq` |
| git | any | pre-installed on most systems |

Verify all tools at once:
```bash
bash scripts/setup.sh
```

---

## Step 1 — AWS Credentials

Choose one method:

**Option A — IAM User keys (simplest):**
```bash
aws configure
# Enter: Access Key ID, Secret Key, Region (e.g. ap-south-1), output format (json)
```

**Option B — Named profile:**
```bash
aws configure --profile secure-ntier
export AWS_PROFILE=secure-ntier
```

**Option C — Environment variables:**
```bash
cp .env.aws.example .env.aws
# Edit .env.aws with your actual keys and region
source .env.aws
```

Verify credentials work:
```bash
aws sts get-caller-identity
```

---

## Step 2 — Configure Terraform Variables

```bash
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
```

Open `terraform/environments/dev/terraform.tfvars` and set **at minimum**:

```hcl
aws_region         = "ap-south-1"        # your AWS region
notification_email = "you@example.com"  # for CloudWatch alarm emails
```

> **Cost note (dev defaults):**
> - 2× `t3.micro` EC2 = ~$15/month
> - 1× `db.t3.micro` RDS = ~$15/month
> - 1× NAT Gateway = ~$35/month
> - **Total: ~$65/month** — remember to `make tf-destroy` when done!
>
> To minimize cost: set `nat_gateway_count = 1` (already default in dev).

---

## Step 3 — Deploy (One Command)

```bash
make deploy-aws
# or directly:
bash scripts/deploy-to-ec2.sh ap-south-1 dev
```

This runs all 7 steps automatically:

```
Step 1/7  Preflight checks         (tools + AWS auth)
Step 2/7  Bootstrap state backend  (S3 bucket + DynamoDB lock)
Step 3/7  Terraform apply          (VPC, ALB, ASG, RDS, ECR, IAM…)
Step 4/7  Build Docker images      (backend + frontend)
Step 5/7  Push to ECR              (login + docker push)
Step 6/7  ASG rolling deploy       (SSM update + instance refresh)
Step 7/7  Smoke test               (polls /health until 200 OK)
```

**Expected duration:** ~12–15 minutes (RDS takes longest ~5 min).

---

## Step 4 — Verify

```bash
# Get the ALB URL
cd terraform && terraform output app_url

# Health check
curl http://<ALB_URL>/health
# Expected: {"status":"ok","db":"connected","environment":"production"}

# API smoke test
curl http://<ALB_URL>/api/items
# Expected: 401 Unauthorized (correct — no token yet)
```

### AWS Console checks
| Service | What to verify |
|---|---|
| **EC2 → Target Groups** | 2 instances "healthy" (green) |
| **EC2 → Auto Scaling Groups** | `secure-ntier-dev-asg` — 2/2 instances |
| **RDS** | `secure-ntier-dev-db` — Available, Multi-AZ=No (dev), Encrypted=Yes |
| **ECR** | `secure-ntier-dev-backend` + `secure-ntier-dev-frontend` repos with image |
| **CloudWatch → Alarms** | 5+ alarms created (in OK state) |

---

## Step 5 — Re-Deploy (After Code Changes)

When you push new code, the CI/CD pipeline handles deployment automatically.
For a manual re-deploy without Terraform:

```bash
make push-aws TAG=$(git rev-parse --short HEAD)
# or:
bash cicd/scripts/registry-login.sh ap-south-1
bash cicd/scripts/stack-push.sh $(git rev-parse --short HEAD) ap-south-1 secure-ntier dev
bash cicd/scripts/deploy-ec2.sh $(git rev-parse --short HEAD) ap-south-1 dev secure-ntier
```

---

## Step 6 — Local Dev (No AWS)

Run the full stack locally without any AWS dependency:

```bash
make local-up
# or:
bash scripts/local-up.sh
```

| Endpoint | URL |
|---|---|
| Frontend | http://localhost |
| Backend API | http://localhost:3000 |
| Health check | http://localhost:3000/health |

Stop:
```bash
bash scripts/local-up.sh --down
```

Reset (wipe DB):
```bash
bash scripts/local-up.sh --reset
```

---

## Step 7 — Tear Down

> [!CAUTION]
> This destroys ALL infrastructure including the RDS database. Back up any data first.

```bash
make tf-destroy
# or:
cd terraform
terraform destroy \
  -var="cloud=aws" \
  -var-file="environments/dev/terraform.tfvars"
```

---

## Troubleshooting

### "ECR repository not found" during docker push
The ECR repo is created by `terraform apply`. Ensure Step 3 completed successfully.

### "Instance refresh not converging"
Check instance bootstrap logs via SSM:
```bash
aws ssm start-session --target <instance-id>
# then inside:
tail -f /var/log/user-data.log
```

### "Health check failing after deploy"
1. Check the ALB target group — are instances registering?
2. Check container logs: `docker compose -f /opt/app/docker-compose.yml logs`
3. Verify the SSM image parameter was updated: `aws ssm get-parameter --name /secure-ntier/dev/backend-image`

### Terraform state lock
If a plan was interrupted:
```bash
cd terraform
terraform force-unlock <lock-id>
```

---

## Architecture Reference

```
Internet
   │
   ▼
Route 53 (optional DNS)
   │
   ▼
AWS WAF  (SQLi / XSS / bot protection)
   │
   ▼
ALB  ─── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
   │
   ▼
EC2 ASG  ─── App Subnets (10.0.11.0/24, 10.0.12.0/24)
│ (Ubuntu 24.04 + Docker Compose)
│ Images pulled from ECR via instance role
│
▼
RDS PostgreSQL  ─── DB Subnets (10.0.21.0/24, 10.0.22.0/24)
(Encrypted, no public access, credentials in Secrets Manager)
```

All infrastructure is defined as code in `terraform/cloud/aws/`. Add resources by editing Terraform — never click in the AWS Console.
