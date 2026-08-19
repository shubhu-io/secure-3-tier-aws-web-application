# Terraform Deployment Guide

This guide takes the repository from zero to a deployed AWS platform.

> ⚠️ **COST WARNING** — `terraform apply` creates EC2, ALB, NAT Gateway, RDS,
> WAF, and CloudWatch resources. These cost money. See
> [`docs/cost-guide.md`](../cost-guide.md). Always run `terraform destroy`
> when done.

## 0. Understand the Terraform workflow

```text
terraform init     - download providers + modules, connect the backend
terraform fmt      - format the code consistently
terraform validate - static check for errors
terraform plan     - show what WILL change (no changes made)
terraform apply    - make the changes
terraform destroy  - remove everything Terraform manages
```

## 1. Configure the environment variables

```bash
cd terraform
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Edit `environments/dev/terraform.tfvars`:

- `aws_region` — your region.
- `notification_email` — your email (alarm notifications; you must confirm
  the SNS subscription email).
- `domain_name` — leave empty for HTTP-only dev, or set your subdomain for
  HTTPS.
- Adjust instance/db sizes if you want cheaper resources (e.g.
  `asg_desired_capacity = 1`).

Also edit `environments/dev/backend.hcl` to point at **your** state bucket.

## 2. Initialize

```bash
terraform init -backend-config="environments/dev/backend.hcl"
```

**Expected output (end):**

```text
Terraform has been successfully initialized!
```

### If it fails

| Error | Fix |
| ----- | --- |
| `Initializing the backend... Failed to get existing workspaces` | The S3 bucket/DynamoDB table don't exist or the bucket name is wrong → create them ([aws-setup.md](./aws-setup.md)) |
| `AccessDenied` on the bucket | IAM user lacks S3/DynamoDB permissions → check your IAM user |
| `Error installing provider` | Internet/proxy issue → rerun `terraform init` |

## 3. Format and validate

```bash
terraform fmt -recursive
terraform validate
```

**Expected output:** `Success! The configuration is valid.`

## 4. Plan

```bash
terraform plan -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan
```

**Expected output:** a long list of "will be created" resources, ending with:

```text
Plan: 60 to add, 0 to change, 0 to destroy.
```

> Review the plan! This is the review-before-apply step that makes IaC safe.
> The exact resource count varies by provider version.

### If it fails

| Error | Fix |
| ----- | --- |
| `No valid credential sources found` | `aws configure` is missing/wrong; verify `aws sts get-caller-identity` |
| `Error: creating EC2 ... InvalidAMIID.NotFound` | Region has a different Ubuntu AMI — the code uses a name filter, usually fine; update the AMI filter if needed |
| `ValidationError: Certificate not found` | Only when `domain_name` is set — the ACM certificate must exist first |

## 5. Apply

```bash
terraform apply plan.tfplan
```

**Expected output:** same resource list, then:

```text
Apply complete! Resources: 60 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "secure-ntier-dev-alb-1234567890.eu-west-1.elb.amazonaws.com"
db_host      = "secure-ntier-dev-db.xxxxx.eu-west-1.rds.amazonaws.com"
...
```

The apply can take **10-20 minutes** (RDS provisioning is the slow part).

### If it fails

| Error | Fix |
| ----- | --- |
| `Error acquiring the state lock` | Someone else is applying, or a stale lock → `terraform force-unlock <LOCK_ID>` only if you're sure nobody is applying |
| `Error creating RDS instance` | Invalid instance class in this region (e.g. `db.t3.micro` unsupported) → change `db_instance_class` |
| `Rate exceeded` on a resource | Transient — rerun `terraform apply` |
| Timeout waiting for WAF | Rerun apply; WAF is eventually consistent |

## 6. First-apply expectation: instances may be "unhealthy" at first

The SSM image parameters start with a placeholder value (`pending`) until the
CI/CD pipeline pushes images. New instances retry `docker compose up` for up
to 5 minutes, then the ASG replaces them and they retry again. This is
**by design** — the pipeline populates the parameters on the first deploy
(next section). Don't panic at "0 healthy targets" before your first pipeline
run.

## 7. Confirm SNS email subscription

AWS emails you at `notification_email` asking you to confirm the SNS
subscription. Click the link in "AWS Notification - Subscription Confirmation".

## 8. Capture your outputs

Keep the Terraform outputs handy:

- `alb_dns_name` → the app URL (HTTP) — this becomes the `ALB_URL` CI secret.
- `image_params` → map of service → SSM parameter name holding its deployed
  image (the pipeline updates these per service).
- `ecr_repository_urls` → the ECR repo URLs (one per service).
- `jenkins_url` / `jenkins_public_ip` → only when `enable_jenkins = true`.

> Optional engines: `enable_eks = true` provisions the EKS cluster (see
> [`docs/deployment/eks.md`](./eks.md)); `enable_jenkins = true` provisions the
> self-hosted CI/CD controller (see [`docs/deployment/jenkins.md`](./jenkins.md)).

## 9. Verify the infrastructure

```bash
bash scripts/verify.sh <region> <project> <env> <alb-url>
```

Or one by one:

```bash
aws autoscaling describe-auto-scaling-groups --region <region>
aws rds describe-db-instances --region <region>
aws wafv2 list-web-acls --scope REGIONAL --region <region>
aws cloudwatch describe-alarms --region <region>
```

## 10. Re-deploy / change infrastructure

Change the `.tfvars`, then repeat: `fmt → validate → plan → apply`. State
lock + plan diff make concurrent changes safe.

## Destroy

```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

Confirm with `yes`. Then check the **manual cleanup** list in
[`scripts/cleanup.sh`](../../scripts/cleanup.sh) (S3 buckets, Route 53,
log groups, final DB snapshots).
