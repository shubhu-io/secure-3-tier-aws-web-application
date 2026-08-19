# Cost Guide & Cost Safety

> ⚠️ **COST WARNING**
>
> This project deploys **billable AWS resources**. It is not free. The monthly
> bill for the default dev stack is roughly **$100–$140/month** while running
> (before free tier). You can avoid most of it by testing locally for free and
> by destroying everything when you finish. Treat every price here as an
> **estimate** — check the current [AWS Pricing](https://aws.amazon.com/pricing/)
> page for your region, and enable a **billing alarm** (see phase 03).

This guide has three parts:

1. Cost breakdown — what you're paying for and why.
2. The cheap path — dev / learning configuration.
3. The production path — what extra costs to expect and why they're justified.

---

## 1. Cost breakdown (default dev stack, approx. per month)

| Resource | Estimate / month | Notes | Cheaper/skip lever |
| -------- | ---------------- | ----- | ------------------ |
| **NAT Gateway** | ~$32 + data | Flat hourly fee + per-GB. The single biggest line item. | Use **none** (single-instance VPC) or one in dev; re-evaluate in prod |
| **EC2** (2 × t3.micro) | ~$15 | On-demand, 2 instances to satisfy the multi-AZ design | `desired_capacity=0` when idle; scale down |
| **RDS** (db.t3.micro, single-AZ) | ~$13 + storage + backup | Instance hours + gp3 storage + 7-day backups | destroy when not testing; skip backups in dev if disposable |
| **ALB** | ~$18 | Per-hour + LCU (very small load) | destroy when unused |
| **EBS** (2 × 20GB gp3) | ~$2.5 | Encrypted gp3, 2 instances | included with EC2 line roughly |
| **CloudWatch** | ~$1–5 | Custom metrics + log storage, flow logs, dashboard | delete log groups before teardown |
| **WAF** | ~$5–7 | Managed rule groups + ACL | small but real |
| **Secret Manager** | ~$0.40 | per secret | one secret |
| **ECR** | ~$0 | storage is tiny | free tier generous |
| **Data transfer** | ~$1–3 | reasonable dev use | trivial in dev |
| **CloudTrail** (to S3) | ~$0–2 | trail itself free; S3 storage tiny | keep |
| **EKS** *(optional)* | ~$73 control plane + ~$50 node group (2 × t3.medium) | Only when `enable_eks=true`; the most expensive add-on | leave `enable_eks=false` unless actively learning Kubernetes |
| **Jenkins** *(optional)* | ~$15–25 (1 × t3.medium + EBS) | Only when `enable_jenkins=true`; overlaps GitHub Actions | run one CI/CD engine per repo |

> **Rough dev running total: ≈ $95–$140/month** (≈ $220+/month with EKS,
> ≈ $240+ with EKS **and** Jenkins enabled). "Running" = the resources exist.
> Every day they exist, you pay. This is why cleanup matters.

**Free tier offsets (may apply, depends on your account age):**

- 750 hours t3.micro/t2.micro — covers **2 × t3.micro for ~15 days/month** each,
  or 1 instance full time.
- 750 hours db.t3.micro (currently **not** all regions) — check your region.
- 5GB EBS, some ALB/ELB hours, 1GB CloudWatch, some S3/ECR storage.

---

## 2. Development / learning configuration (cheapest)

Goal: prove the architecture at minimal cost, destroy when done.

| Setting | Dev value | Effect |
| ------- | --------- | ------ |
| `instance_type` | `t3.micro` | cheapest general purpose |
| `asg_min_size` / `desired` | `2` (or `1` if you accept single-AZ dev) | fewer instances = cheaper |
| `nat_gateway_count` | `1` | halves NAT spend vs 2 |
| `db_instance_class` | `db.t3.micro` | cheapest DB |
| `db_multi_az` | `false` | no standby replica |
| `db_allocated_storage` | `20` GB gp3 | 20 GB default; don't inflate |
| `backup_retention_days` | `7` | enough for DR drills |
| `deletion_protection` | `false` | destroy must actually work |
| `domain_name` | `""` | skip ACM + Route 53 (plain HTTP ALB) |
| `enable_detailed_monitoring` | auto-`false` for dev | avoids 1-min metric cost |
| `enable_eks` / `enable_jenkins` | `false` | both optional engines are costly — leave off unless learning them |

**Free-est learning path:** run the application 100% locally.

```bash
cd docker
docker compose up --build
```

No AWS spend at all. Use AWS only for: ECR image push drills, Terraform
validation (`terraform validate` is free), and short-lived `terraform apply`
experiments that end with `terraform destroy` within hours.

**Half-price suggestion:** instead of a persistent environment, do
`terraform apply` → run your tests/verification → `terraform destroy` in the
same afternoon. You pay only for the hours used.

---

## 3. Production configuration (what + why it costs more)

| Setting | Prod value | Why the extra cost is justified |
| ------- | ---------- | ------------------------------- |
| `nat_gateway_count` | `2` | one per AZ — egress survives an AZ failure |
| `db_multi_az` | `true` | synchronous standby → RPO≈0, automatic failover |
| `deletion_protection` | `true` | humans can't accidentally delete the DB |
| `instance_type` / `db_instance_class` | bigger (per workload) | headroom for load + bursts |
| `backup_retention_days` | `≥ 14` (or 35 for compliance) | longer restore window |
| `domain_name` + ACM/Route 53 | set | HTTPS, stable URL (Route 53 ~$0.50/hosted zone) |
| `enable_access_logs` | ALB S3 logs | audit trailer |
| `enable_detailed_monitoring` | `true` (prod auto) | 1-minute metrics = faster alarms |
| WAF rate-limit / geo rules | add | targeted protection (small add) |

A realistic small prod with these: **≈ $200–350/month** (before traffic).

---

## 4. Top cost culprits & how to control them

1. **NAT Gateway** — flat hourly (~$0.045/h × 730 h ≈ $32/instance). The #1
   surprise. Dev: keep 1. Never leave it running at 2 with no app traffic.
2. **RDS** — instance + storage + backup + any reserved-size provisioning.
   Destroy dev DBs; snapshot the important ones; don't oversize storage
   (`max_allocated_storage` auto-scaling can creep up).
3. **ALB** — hourly + LCUs. Idle = still billed. Destroy when not testing.
4. **EC2 ×2** — every hour. Set `asg_desired_capacity = 0` when the platform
   isn't needed (keeps VPC/DB/alarm state).
5. **CloudWatch** — log volume and custom metrics. Flow logs are the largest
   typical contributor; use retention limits (`flow_logs_retention_days`).
6. **Data transfer** — small in dev; watch in prod with users.

---

## 5. Free-tier style budget testbed (single AZ)

If you want the *cheapest real deployment* that still proves the design
(single-AZ, not production):

```hcl
# terraform/environments/dev/terraform.tfvars
instance_type        = "t3.micro"
asg_min_size         = 1
asg_desired_capacity = 1
asg_max_size         = 2
nat_gateway_count    = 1
db_instance_class    = "db.t3.micro"
db_multi_az          = false
backup_retention_days = 7
```

Flex bucket: single EC2 + NAT + single-AZ rds ≈ **$45–60/month** while running.

---

## 6. Cleanup checklist (stop the meter)

```bash
cd terraform
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

Then finish the manual items (this is the part people forget):

| Resource | Why manual | Action |
| -------- | ---------- | ------ |
| CloudWatch Log Groups | not removed by `destroy` (flow logs, app logs) | delete via console/cli |
| S3 buckets (`*-cloudtrail`, `*-alb-logs`) | `force_destroy=true` empties them, buckets removed only if in same state | verify removal |
| Route 53 hosted zone | often created outside Terraform | delete if unused |
| Secrets Manager leftover secret versions | cheap but shouldn't linger | remove |
| GitHub secrets / IAM access keys | outside AWS resources | remove when unused |

Quick sweep:

```bash
bash scripts/cleanup.sh eu-west-1 secure-ntier dev
```

---

## 7. Rules of thumb (cost hygiene)

- **Billing alarm from day one** (phase 03): know the meter is spinning.
- **Never leave a deployed dev stack idle all week** unless you want to pay for it.
- **Prefer "apply → test → destroy"** bursts over a permanently-running env.
- **Track who runs what**: each environment has its own state/key → cost
  attribution by owner.
- **Document expected costs** in the PR that changes resource sizing.