# Full Build Guide — 31 Phases

> This document takes you from an empty AWS account to a running, secure,
> monitored n-tier platform — **one small, verifiable phase at a time**.
>
> Every phase follows the same structure so you always know `what`, `why`,
> and `how to verify` before moving on:
>
> ```text
> Objective → Why → Architecture → Folder structure → Files → Commands
>   → Expected output → Verification → Common errors → Troubleshooting
>   → Security notes → Production notes → Completion checklist → Next phase
> ```
>
> The whole guide maps 1:1 to the code in this repository. Read the phase,
> run the commands, tick the checklist, move on. Do **not** skip phases or run
> everything at once.

> **Multi-cloud note:** these phases were written against AWS and remain the
> reference implementation, but they are **cloud-generic** now. The Terraform
> root dispatches to one self-contained module per cloud
> (`terraform/cloud/aws|azure|gcp`, selected with `-var="cloud=..."`), and the
> Azure/GCP equivalents are named inline where trivial (e.g. VPC ↔ VNet ↔ VPC,
> RDS ↔ Azure PostgreSQL Flexible Server ↔ Cloud SQL). Where a phase names an
> AWS service, read it as the concept; per-cloud setup guides live in
> [`deployment/`](./deployment/). The Azure/GCP modules are ports pending live
> validation.

---

## How to use this guide

| Thing | Where it lives |
| ----- | -------------- |
| Infrastructure code | `terraform/` |
| Application code | `application/` |
| Container files | `docker/` |
| Kubernetes (optional) | `kubernetes/` + `terraform/modules/eks/` |
| CI/CD pipelines | `.github/workflows/` + `cicd/scripts/` |
| Tech-stack manifest | `stack.json` (services, ports, toolchains, DB engine/version, runtimes) |
| Jenkins (optional) | `cicd/Jenkinsfile`, `cicd/Jenkinsfile-ci`, `terraform/modules/jenkins/` |
| Security policies | `security/iam/`, `security/waf/` |
| Monitoring | `terraform/modules/monitoring/`, `monitoring/` |
| Tests | `tests/` |
| Other docs | `docs/` (architecture, deployment, operations, runbooks, ADRs) |

**Golden rule for every phase:** run the verification commands. If a phase
cannot be verified, stop and fix it before continuing — a broken foundation
breaks everything built on top of it.

---

## Before phase 01

Complete [`deployment/prerequisites.md`](./deployment/prerequisites.md) and
[`deployment/aws-setup.md`](./deployment/aws-setup.md) so you have:

- ✅ Terraform ≥ 1.5
- ✅ Docker + Docker Compose
- ✅ Node.js 20+
- ✅ AWS CLI v2, configured (`aws configure`) with an IAM user
- ✅ Git + a GitHub account
- ✅ (one-time, phase 05) a `terraform-locks` DynamoDB table and an encrypted
  S3 bucket for state

---

# PART A — Foundations (01–04)

---

## Phase 01 — Project Planning & Requirements

### Objective

Define *what* is being built, *why*, and *how success is measured* before
writing any code.

### What we are building

A three-tier web platform on AWS:

```text
Tier 1  Public    ALB + NAT Gateway (public subnets)
Tier 2  App       EC2 instances running Docker (private app subnets)
Tier 3  Data      RDS PostgreSQL (private DB subnets)
```

delivered through CI/CD, secured with WAF + layered security groups + Secrets
Manager, and monitored with CloudWatch alarms.

### Why we need it

Production applications need: repeatable infrastructure (Terraform),
resilience (multi-AZ + Auto Scaling), security (private tiers, least
privilege), automation (CI/CD), and observability. This project builds all of
those as one coherent, executable system.

### Architecture

See [`diagrams/architecture.png`](../diagrams/architecture.png) and
[`docs/architecture/overview.md`](./architecture/overview.md).

### Components

| Component | Responsibility |
| --------- | -------------- |
| VPC + subnets | Isolated network with public / app / DB tiers |
| ALB | TLS termination, routing, health checks |
| EC2 + ASG | Stateless application tier, self-healing |
| RDS | Managed, encrypted PostgreSQL |
| ECR | Private container registry |
| WAF | Web attack filtering |
| Secrets Manager | Runtime credentials |
| CloudWatch + SNS | Alerts |
| GitHub Actions | CI/CD |

### Folder structure

The full repository layout is described in the root
[`README.md`](../README.md#-repository-structure). No files are created in this
phase — it is a planning only phase.

### Commands

None.

### Expected output

A written, agreed understanding of:

1. **Goal:** auto-deploy a React + Node + PostgreSQL app to a secure n-tier AWS platform.
2. **Non-goals** (explicitly out of scope): ECS Fargate, multi-account orgs,
   cross-region DR. (Kubernetes/EKS was moved **in** scope — see phase 30.)
3. **Success criteria:** one `terraform apply` builds the platform; pushing to
   `main` deploys the app; killing an EC2 instance is self-healed.

### Verification

You can answer "yes" to: *Do I understand what each tier is for and why the
platform is split into public / app / database tiers?*

### Common errors

None (planning phase).

### Security notes

Security is designed from phase 01, not bolted on at the end: private DB
tier, layered security groups, secrets outside the repository.

### Production notes

- Every decision in this project is an **Architecture Decision** — recorded in
  [`docs/adr/`](./adr/). Read ADR-001…ADR-008 to see *why* the choices were made.

### Beginner explanation

- **Tier** = a layer of the application with a distinct job and distinct network
  access. The database is the most sensitive layer, so it sits in its own
  private network segment.
- **n-tier** = multiple such layers (here: 3).

### Interview questions

- *"Why split a VPC into three tiers?"* — each tier has different access needs
  and a different blast radius; isolating them with subnets + security groups
  limits how far an attacker can move if one layer is compromised.

### Phase completion checklist

- [ ] Executed nothing, but documented the goal, non-goals and success criteria

### Next phase

Phase 02 — Repository Setup.

---

## Phase 02 — Repository Setup

### Objective

Create the Git repository and base files so every later phase has a home.

### Why we need it

Version control + a documented layout make the work reviewable, recoverable,
and reproducible. The `.gitignore` prevents secrets and state from ever being
committed.

### Architecture

A monorepo: infra, app, containers, pipelines, and docs live together so a
change in code and a change in infra land in the same pull request.

### Folder structure

```text
secure-ntier-cloud-platform/
├── README.md
├── LICENSE
├── .gitignore
├── CONTRIBUTING.md
├── SECURITY.md
├── CHANGELOG.md
├── docs/
├── terraform/
├── application/
├── docker/
├── cicd/
├── security/
├── monitoring/
├── scripts/
├── tests/
├── diagrams/
└── screenshots/
```

### Files

- `README.md` — the project's front door
- `LICENSE` — MIT
- `.gitignore` — ignores `.env`, `*.tfvars`, `*.tfstate*`, `node_modules`, `*.pem`, keys
- `CONTRIBUTING.md` — how to contribute
- `SECURITY.md` — how to report vulnerabilities
- `CHANGELOG.md` — notable changes per release

### Commands

Init the repository (from the project root *after* the folder name):

```bash
git init
git add .
git commit -m "feat: scaffold project structure"
```

### Expected output

A clean, committed skeleton that contains **no** secrets, no `node_modules`,
and no `.tfstate` files.

### Verification

```bash
git status                 # working tree clean
cat .gitignore              # confirm .env, *.tfstate, node_modules are ignored
git log --oneline           # shows the initial commit
```

### Common errors

- **Secrets committed** → remove from history, rotate the secret. Prevention:
  `.gitignore` entries + secret scanning (we use `trivy` + npm audit in CI).

### Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `node_modules` committed | `git rm -r --cached node_modules` then commit the `.gitignore` |

### Security notes

Never commit `.env`, `*.pem`, `terraform.tfvars` (only `.example` files), or
`.tfstate` (state contains secrets).

### Production notes

- Use a branching strategy: `main` (production), `develop`, `feature/*`, `bugfix/*`.
- Commit conventions: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `security:`.

### Beginner explanation

- **Git** snapshots your project so any change can be reviewed and undone.
- **.gitignore** is a list of files Git must never track (secrets, caches, build output).

### Interview questions

- *"What should never be committed to Git?"* — secrets, keys, Terraform state
  (it contains secrets), build artifacts, and dependencies that can be
  re-installed.

### Phase completion checklist

- [ ] `.gitignore` covers `.env`, `*.tfvars`, `*.tfstate*`, keys, `node_modules`
- [ ] README, LICENSE, CONTRIBUTING, SECURITY, CHANGELOG exist
- [ ] Initial commit created; tree clean

### Next phase

Phase 03 — AWS Account Preparation.

---

## Phase 03 — AWS Account Preparation

### Objective

Prepare the AWS account: choose a region, enable billing alerts, and create
where everything lives.

### Why we need it

A clean, monitored account prevents surprise bills and makes later phases
(ECR, RDS, NAT…) work smoothly.

### Architecture

See [`docs/deployment/aws-setup.md`](./deployment/aws-setup.md) — a checklist of
AWS Console steps.

### Commands

```bash
# Confirm CLI identity + effective region
aws sts get-caller-identity
aws configure list
```

### Expected output

```text
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/devops-user"
}
```

### Verification

- IAM user works = `aws sts get-caller-identity` returns your user.
- Region set = `aws configure list` shows it.
- **Optional but recommended:** a billing alarm at $X so you are emailed
  before costs ramp.

### Common errors

- **AccessDenied** → the IAM user lacks permissions; add `Amazon EC2 Full
  Access`, `AmazonVPCFullAccess`, `AmazonRDSFullAccess`, `AmazonS3FullAccess`,
  `IAMFullAccess`, `AmazonSSMFullAccess`, `AmazonEC2ContainerRegistryFullAccess`,
  `AWSCertificateManagerFullAccess`, `AmazonRoute53DomainsFullAccess`,
  `AmazonCloudWatchFullAccess`, `SecretsManagerReadWrite`, `AWSLambda_FullAccess`
  (documented in aws-setup.md).

### Security notes

- Never run from the **root** account. Create an IAM user with least-privilege
  for daily work and an MFA-protected role (or temporary credentials) for
  privileged actions.

### Beginner explanation

- **IAM** = Identity and Access Management: who (user/role) may do what (policy).
- **Region** = which AWS data center cluster you operate in.

### Interview questions

- *"Why not use the root account?"* — Root has unlimited access; if it is
  compromised the account is lost. IAM users with scoped policies bound by MFA
  are far safer.

### Phase completion checklist

- [ ] IAM user created with programmatic keys
- [ ] `aws sts get-caller-identity` succeeds
- [ ] Billing alarm configured (recommended)

### Next phase

Phase 04 — IAM Setup.

---

## Phase 04 — IAM Setup

### Objective

Create the **identity layer**: least-privilege IAM roles for instances and
CI/CD, plus an admin user for you.

### Why we need it

Computers and pipelines need permissions, but only the minimal ones. This is
the foundation of the security architecture.

### Architecture

```text
EC2 instances ── instance role (pull ECR, read SSM/Secrets, write logs)
GitHub Actions ── CI/CD role/user (push ECR, update SSM params, start refresh)
Engineer       ── IAM user (Terraform + ops)
```

### Files

- `security/iam/backend-instance-policy.json` — the instance's permissions
- `security/iam/cicd-policy.json` — the CI/CD permissions
- `terraform/modules/compute/main.tf` — the instance role (resources)
- `terraform/main.tf` — the CI/CD IAM policy resource (lines 256–321)

### Commands

```bash
aws iam create-user --user-name cicd-deployer
aws iam create-access-key --user-name cicd-deployer
# attach the cicd policy (arn printed by terraform in a later phase)
aws iam attach-user-policy \
  --policy-arn arn:aws:iam::AWS::policy/... \
  --user-name cicd-deployer
```

### Expected output

A user with an access key that you will later store as GitHub secrets
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.

### Verification

- The IAM policy documents in `security/iam/` grant **only** the actions used
  by the instance / CI/CD scripts:
  - Instance: `ssm:GetParameter`, `secretsmanager:GetSecretValue`,
    `ecr:*Pull*`, `logs:CreateLogStream` / `PutLogEvents` + `AmazonSSMManagedInstanceCore`.
  - CI/CD: ECR push, SSM put/update image params, ASG instance refresh,
    target-health / cloudwatch reads.

### Common errors

- **Over-permissioned policy** → a developer may argue "just give me `*`", but
  least privilege means exactly the actions needed, scoped to the resource ARNs.

### Security notes

- The instance role has **no** permissions to manage infrastructure — it can
  only do what its boot script needs.
- CI/CD has no `iam:*` — a compromised pipeline cannot mint new users.

### Beginner explanation

- **Role** = a set of permissions a service "assumes" (an instance assumes its
  role at boot, no keys on the disk).
- **Least privilege** = give each identity only the permissions its job
  requires.

### Interview questions

- *"How does an EC2 instance authenticate to ECR without keys?"* — its IAM
  instance role grants `ecr:GetAuthorizationToken`; the instance calls
  `ecr get-login-password` with its role credentials.

### Phase completion checklist

- [ ] IAM user for you (with console + programmatic access)
- [ ] IAM policies for instance + CI/CD drafted in `security/iam/`
- [ ] Role used by instances is wired in `terraform/modules/compute/main.tf`
- [ ] CI/CD policy in `terraform/main.tf` (applied via Terraform in phase 21)

### Next phase

Phase 05 — Terraform Backend.

---

# PART B — Network (05–10)

---

## Phase 05 — Terraform Backend & State

### Objective

Set up remote state (S3) with locking (DynamoDB) so Terraform state is shared,
encrypted, and safe from concurrent applies.

### Why we need it

Terraform stores the mapping of code → real resources in a **state file**.
Local state is lost/replaced easily and locks nothing; remote state on S3 with
DynamoDB locking is the production pattern.

### Architecture

```text
terraform apply ──► S3 bucket (state, encrypted, versioned)
                    DynamoDB table (LockID) – mutual exclusion
```

### Files

- `terraform/backend.tf`
- `terraform/environments/dev/backend.hcl`
- `terraform/environments/prod/backend.hcl`

### Complete code

`backend.tf`:

```hcl
terraform {
  backend "s3" {}
}
```

Values are injected per environment with `-backend-config`.

### Commands (one-time AWS resource creation)

```bash
# Create the S3 bucket (versioning + encryption)
aws s3api create-bucket --bucket your-org-terraform-state --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket your-org-terraform-state \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket your-org-terraform-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create the locking table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then, **from `terraform/`**:

```bash
terraform init -backend-config="environments/dev/backend.hcl"
terraform fmt -recursive
terraform validate
```

### Expected output

`terraform init` ends with:

```text
Success! Terraform has initialized the workspace.
```

### Verification

- `terraform validate` → `Success! The configuration is valid.`
- After the first `apply`, `aws s3 ls your-org-terraform-state` shows the
  `terraform.tfstate` object.

### Common errors

- **Bucket naming** — bucket names are globally unique; add your org/account.
- **Lock table missing** — `Error acquiring the state lock` → create the
  DynamoDB table.

### Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Backend initialization required` | run `terraform init -backend-config=...` |
| State locked by a crashed run | `terraform force-unlock <LOCK_ID>` (only after confirming no apply is running) |

### Security notes

- State contains secrets (`random_password` values). The S3 bucket is
  encrypted (AES256 or KMS) and **never committed to Git**.

### Production notes

- Give prod its own state key: `backend.hcl` → `key = "secure-ntier/prod/..."`.
- Use separate buckets (or at least separate keys) per environment to isolate
  blast radius.

### Beginner explanation

- **State** = Terraform's memory of what it created, so the next run knows what
  to change/delete.
- **Locking** = prevent two people from running `apply` at the same time on the
  same state.

### Interview questions

- *"Why remote state?"* — shared, recoverable, encryptable, lockable; local
  state is single-machine and easy to corrupt or lose.

### Phase completion checklist

- [ ] S3 bucket with versioning + encryption exists
- [ ] DynamoDB `terraform-locks` table exists
- [ ] `terraform init` with backend config succeeds
- [ ] `terraform validate` passes

### Next phase

Phase 06 — VPC.

---

## Phase 06 — VPC

### Objective

Create the Virtual Private Cloud — an isolated network for everything.

### Why we need it

A VPC gives the platform its own IP space, DNS, and network isolation. Without
it resources share AWS's default network with AWS-owned clutter and other
experiments.

### Architecture

```text
VPC 10.0.0.0/16 ── 6 subnets (see phase 07) + Internet Gateway
```

### Files

- `terraform/modules/vpc/main.tf` — `aws_vpc`, `aws_internet_gateway`
- `terraform/modules/vpc/variables.tf`, `outputs.tf`

### Complete code (key resource)

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr          # 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}
```

### Commands

```bash
# from terraform/
cd terraform
terraform init -backend-config="environments/dev/backend.hcl"
terraform plan -var-file="environments/dev/terraform.tfvars"
```

Until this point you can validate with a local (no-apply) plan. Apply is done
when the network stack is complete (after phase 09) — but you may apply now to
verify the VPC alone:

```bash
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```

### Expected output

`aws_vpc.this` created with id like `vpc-0a1b2c3d4e5f67890`.

### Verification

```bash
aws ec2 describe-vpcs --region ap-south-1
aws ec2 describe-internet-gateways --region ap-south-1
```

### Common errors

- **CIDR too /16** structural choice, fine here. Changing the VPC CIDR later
  requires re-creating the VPC.

### Security notes

- Enable DNS hostnames/support (needed by RDS endpoint resolution).

### Production notes

- Keep one VPC per environment (dev and prod do **not** share a VPC).

### Beginner explanation

- **VPC** = your own private data-center-in-the-cloud: a virtual network with
  your own IP addresses where you control routing and access.

### Interview questions

- *"What is a VPC and what does it contain?"* — an isolated virtual network
  containing subnets, route tables, gateways, security groups, and ACLs that you
  fully control.

### Phase completion checklist

- [ ] `aws_vpc` with CIDR 10.0.0.0/16 created
- [ ] Internet Gateway created and attached

### Next phase

Phase 07 — Subnets.

---

## Phase 07 — Subnets

### Objective

Divide the VPC into **6 subnets** across 2 availability zones in 3 tiers.

### Why we need it

Subnets are the network slices that (with route tables + security groups)
enforce the public/app/DB tiering that the whole architecture depends on.

### Architecture

| # | Subnet | CIDR | AZ | Purpose |
| - | ------ | ---- | -- | ------- |
| 1 | public-1 | 10.0.1.0/24 | AZ-a | ALB, NAT |
| 2 | public-2 | 10.0.2.0/24 | AZ-b | ALB, NAT |
| 3 | app-1 | 10.0.11.0/24 | AZ-a | EC2 (private) |
| 4 | app-2 | 10.0.12.0/24 | AZ-b | EC2 (private) |
| 5 | db-1 | 10.0.21.0/24 | AZ-a | RDS (private) |
| 6 | db-2 | 10.0.22.0/24 | AZ-b | RDS (private) |

### Subnet calculation

From `/16` (65,536 addresses) we carve the last byte (256 addresses each):

```text
10.0.00000001 = 10.0.1.0/24    public-a
10.0.00000010 = 10.0.2.0/24    public-b
10.0.00001011 = 10.0.11.0/24   app-a
10.0.00001100 = 10.0.12.0/24   app-b
10.0.00010101 = 10.0.21.0/24   db-a
10.0.00010110 = 10.0.22.0/24   db-b
```

`/24` = 256 IPs (usable ~251). This leaves plenty of room in the `/16` for
future tiers or expansion.

### Files

- `terraform/modules/vpc/main.tf` — the three `aws_subnet` resources
  (`public`, `app`, `db`) with `map_public_ip_on_launch` set only for public.

### Complete code (public subnets as representative example)

```hcl
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true     # only public tier

  tags = {
    Name        = "${local.name_prefix}-public-${element(var.azs, count.index)}"
    Tier        = "public"
    Environment = var.environment
  }
}
```

### Commands

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```

### Expected output

Six subnets with the expected CIDRs and AZs:

```bash
aws ec2 describe-subnets --region ap-south-1 --query 'Subnets[*].{CIDR:CidrBlock,AZ:AvailabilityZone,Pub:MapPublicIpOnLaunch}'
```

### Verification

- 2 public subnets with `MapPublicIpOnLaunch = true`
- 2 app + 2 db subnets with `MapPublicIpOnLaunch = false`

### Common errors

- **AZ mismatch** — the `azs` list must have at least as many entries as the
  longest subnet list (2). If you pin fewer/more, CIDR→AZ pairing skews.

### Security notes

- Only the public subnets ever get public IPs. App and DB instances have no
  public visibility at all.

### Production notes

- Subnets span two AZs → multi-AZ for ALB, ASG, and RDS (choosing the same AZ
  list keeps load and DB in the same two zones).

### Beginner explanation

- **Subnet** = a segment of the VPC's address space bound to one Availability
  Zone. Public = has a route to the internet; private = does not.

### Interview questions

- *"Why 2 subnets per tier?"* — spreading across two availability zones gives
  horizontal resilience: if one AZ fails, the other tier keeps serving.

### Phase completion checklist

- [ ] 6 subnets: 2 public, 2 app, 2 db with correct CIDRs and AZ pairs
- [ ] Only public subnets auto-assign public IPs

### Next phase

Phase 08 — Routing (IGW, NAT, route tables).

---

## Phase 08 — Routing (Internet Gateway + NAT + Route Tables)

### Objective

Make the internet reachable from public subnets (IGW) and only-outbound
reachable from app subnets (NAT), while keeping DB subnets offline.

### Why we need it

Each tier's threat model is encoded in its route table:

```text
Public tier  0.0.0.0/0 → Internet Gateway      (bidirectional)
App tier     0.0.0.0/0 → NAT Gateway            (outbound only)
DB tier      (no default route)                 (fully private)
```

### Files

- `terraform/modules/vpc/main.tf` — `aws_route_table` (public/app/db) +
  `aws_route_table_association` + `aws_eip` + `aws_nat_gateway`

### Complete code (essentials)

```hcl
# Public route table: all traffic to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# NAT per AZ (or single shared in dev: nat_gateway_count=1)
resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

# App route table: outbound only via NAT
resource "aws_route_table" "app" {
  count  = var.nat_gateway_count
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
}

# DB route table: intentionally has NO default route
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
}
```

### Commands

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```

### Expected output

```bash
aws ec2 describe-route-tables --region ap-south-1 \
  --query 'RouteTables[*].Routes[?DestinationCidrBlock==`0.0.0.0/0`][].{Cidr:CidrBlock,GW:GatewayId,NAT:NatGatewayId}'
```

Shows IGW routes for public, NAT routes for app, and **nothing** for DB.

### Verification

- Public: route to `igw-…`
- App: route to `nat-…`
- DB: no `0.0.0.0/0` route

### Common errors

- **NAT is expensive in prod** (`nat_gateway_count=2` doubles the cost).
  Dev uses 1; prod uses 2 (one per AZ for AZ independence).

### Security notes

- NAT gives app instances **outbound** internet (apt, image pulls) with **no
  inbound** exposure. This is why app instances can download packages and Docker
  images without being publicly reachable.

### Production notes

- `nat_gateway_count = 2` (one per AZ) keep egress working if one AZ fails.
  Dev uses 1 to save cost.

### Beginner explanation

- **Internet Gateway** = door to the internet for public resources.
- **NAT Gateway** = a proxy that lets private instances *initiate* outbound
  traffic while the internet can never initiate *inbound* traffic to them.
- **Route table** = the "GPS" attached to each subnet: "to go anywhere, use X".

### Interview questions

- *"Why does the DB subnet have no default route?"* — defense in depth: even if
  the DB accidentally had a public IP, it could not route to the internet, and
  ordinary outbound exfiltration is blocked at the network level.

### Phase completion checklist

- [ ] Public route table → IGW
- [ ] App route table → NAT Gateway
- [ ] DB route table has no default route
- [ ] NAT Gateway(s) + EIPs provisioned

### Next phase

Phase 09 — Security Groups.

---

## Phase 09 — Security Groups (layered firewalls)

### Objective

Create the three security groups that define exactly who can talk to whom.

### Why we need it

Security groups are the **stateful** firewall at the resource level. Layering
them turns the network into a trust chain:

```text
Internet → ALB SG → App SG → DB SG
```

### Files

- `terraform/modules/security/main.tf`

### Complete code (each group shown condensed)

```hcl
resource "aws_security_group" "alb" {
  name = "${local.name_prefix}-alb-sg"
  # inbound 443 + 80 from 0.0.0.0/0
  # egress   all
}

resource "aws_security_group" "app" {
  name = "${local.name_prefix}-app-sg"
  # inbound 80 from security_groups = [aws_security_group.alb.id]
  # (no SSH! admin via SSM Session Manager)
  # egress all
}

resource "aws_security_group" "db" {
  name = "${local.name_prefix}-db-sg"
  # inbound 5432 from security_groups = [aws_security_group.app.id]
  # egress all
}
```

The key pattern: ingress references **another security group by ID**, not a
CIDR. That means "any instance that holds the app SG may connect", which is
portable — you never have to update IPs when instances change.

### Commands

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```

### Expected output

Three security groups. From the [security-tests](../tests/security/security-tests.sh):

```bash
aws ec2 describe-security-groups \
  --group-ids <ALB_SG> <APP_SG> <DB_SG> --region ap-south-1
```

### Verification

- ALB SG: inbound 443 + 80 from `0.0.0.0/0`.
- App SG: inbound 80 **from the ALB SG ID** only.
- DB SG: inbound 5432 **from the App SG ID** only.
- No group opens SSH, no group references `0.0.0.0/0` except the ALB.

### Common errors

- **Timeout rather than "connection refused"** — a security group rule that
  silently drops. The database will appear unreachable because the packet is
  discarded, not rejected.

### Security notes

- **Stateful**: return traffic is automatic — you only define ingress.
- **Self-referencing** is allowed and used in DB→App→ALB chain.
- **No SSH from the internet**: the audit trail is in CloudTrail for SSM
  sessions, and there is no exploitable SSH open port.

### Production notes

- SGs are per-env: dev and prod have completely separate groups.
- Changing an SG rule applies live — no instance restart required.

### Beginner explanation

- **Security group** = a virtual firewall wrapping each resource. Unlike a
  NACL it is stateful: if you allow inbound, the reply is allowed automatically.

### Interview questions

- *"Why reference a security group ID instead of an IP CIDR?"* — it stays valid
  as instances scale and change IPs; it also expresses intent ("traffic from
  the app group"), which is self-documenting.

### Phase completion checklist

- [ ] ALB SG (443/80 from internet)
- [ ] App SG (80 from ALB SG)
- [ ] DB SG (5432 from App SG)
- [ ] No public SSH anywhere

### Next phase

Phase 10 — Network ACLs + VPC Flow Logs (network hardening & audit).

---

## Phase 10 — Network ACLs + VPC Flow Logs

### Objective

Add a stateless second firewall layer (NACLs) per tier and enable network
audit logging (VPC Flow Logs).

### Why we need it

- NACLs protect **even against a misconfigured security group** — a second,
  independent rule set.
- Flow Logs record every accepted/rejected packet so network attacks and bugs
  are traceable.

### Files

- `terraform/modules/vpc/main.tf` (NACLs at lines ~178–388, Flow Logs ~393–455)

### Complete code (public NACL inbound, condensed)

```hcl
resource "aws_network_acl" "public" { vpc_id = aws_vpc.this.id }

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
# + HTTP 80 (110), ephemeral returns (120/130) inbound
# + outbound "*" (100)
```

> NACLs are **stateless**: you must allow the request *and* the reply. That's
> why there are explicit ephemeral-port inbound rules.

### Commands

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```

Then confirm flow logs:

```bash
aws ec2 describe-flow-logs --region ap-south-1 \
  --query 'FlowLogs[*].{Status:FlowLogStatus,Resource:ResourceId}'
```

### Expected output

- 3 NACLs (public/app/db) each associated with its subnets.
- `FlowLogs[0].Status == "ACTIVE"`, destination = CloudWatch log group
  `/aws/vpc-flow-log/secure-ntier-dev`.

### Verification

```bash
# read a few accepted/rejected flows
aws logs filter-log-events --log-group-name /aws/vpc-flow-log/secure-ntier-dev \
  --region ap-south-1 --limit 5
```

### Common errors

- **"Denied" everything after apply** — a NACL rule with the wrong `rule_number`
  or missing egress allowed the request but dropped the reply. Remember NACLs
  need both directions.

### Security notes

- NACL tiers mirror the SG chain: public allows 80/443; app allows 80 from
  public subnet CIDRs; db allows 5432 from app subnet CIDRs. Deny-by-default
  aside from those explicit `allow` rules.
- Flow Logs capture `ACCEPT`/`REJECT` so `security-tests.sh` can prove the DB
  rejects non-app traffic.

### Production notes

- Keep flow-logs retention sensible (14d dev, 90d prod in the root module).
- Flow Logs cost a small amount of CloudWatch storage — worth it for audit.

### Beginner explanation

- **NACL** = a stateless firewall attached to a *subnet* (all instances in it).
- **Flow log** = a network-level diary of every connection.

### Interview questions

- *"NACL vs Security Group?"* — SG: stateful, attached to resources, needs only
  inbound rules. NACL: stateless, attached to subnets, needs inbound **and**
  outbound allow rules. Use both — defense in depth.

### Phase completion checklist

- [ ] Public/app/db NACLs created and associated
- [ ] VPC Flow Logs active and writing to CloudWatch
- [ ] Network stack fully applied; `terraform show` looks correct

### Next phase

Phase 11 — ECR (container registry for the application).

---

# PART C — Application & Containers (11–12)

---

## Phase 11 — ECR (Private Container Registry)

### Objective

Create private Docker registries for the backend and frontend images so CI/CD
can push to them and instances can pull from them.

### Why we need it

Public Docker Hub is not acceptable for production — images must be private,
scannable, and immutable containers of your built code.

### Files

- `terraform/modules/ecr/main.tf`, `terraform/modules/ecr/variables.tf`

### Complete code

```hcl
resource "aws_ecr_repository" "this" {
  count                = length(var.repositories)
  name                 = "${var.project_name}-${var.environment}-${var.repositories[count.index]}"
  image_tag_mutability = "MUTABLE"   # dev; use IMMUTABLE in prod
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true              # each push triggers a scan
  }
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

# List repos
aws ecr describe-repositories --region ap-south-1 \
  --query 'repositories[*].repositoryName'
```

### Expected output

```text
secure-ntier-dev-backend
secure-ntier-dev-frontend
```

### Verification

- Both repositories exist.
- `scan_on_push = true` (scan runs automatically on each `docker push`).

### Common errors

- **ECR auth failed in CI** → ensure the pipeline's IAM user has
  `ecr:GetAuthorizationToken` + repository push permissions (see `security/iam/cicd-policy.json`).

### Security notes

- Repositories live in your AWS account — no public access.
- With `scan_on_push`, vulnerabilities are detected at the moment an image is
  pushed, before it can be deployed.

### Production notes

- Switch `image_tag_mutability` to `IMMUTABLE` + sign images with a KMS signing
  key for production supply-chain controls.

### Beginner explanation

- **ECR** = Amazon's private Docker registry — like Docker Hub but inside your
  AWS account, private and integrated with IAM.

### Interview questions

- *"Why ECR and not Docker Hub?"* — private by default, IAM-integrated,
  regional (low latency), and pushes can auto-trigger vulnerability scans.

### Phase completion checklist

- [ ] `secure-ntier-dev-backend` and `secure-ntier-dev-frontend` repositories exist
- [ ] `scan_on_push` enabled

### Next phase

Phase 12 — Application + Docker.

---

## Phase 12 — Application + Docker

### Objective

Build a real application (React + Node + PostgreSQL) and package it into
production Docker images.

### Why we need it

Everything upstream exists to ship this app: it must have auth, DB access, a
health endpoint, and environment-based configuration so it runs identically in
local Compose, CI, and on EC2.

### Architecture (app)

```text
React (Vite) −index.html → Nginx :80 ──proxy /api──▶ Node/Express :3000 ──▶ PostgreSQL
```

### Files

| File | Purpose |
| ---- | ------- |
| `application/backend/src/server.js` | Boot + real `pg` pool |
| `application/backend/src/app.js` | Express app factory (testable) |
| `application/backend/src/routes/health.js` | `/health`, `/health/ready` |
| `application/backend/src/routes/auth.js` | register/login → JWT |
| `application/backend/src/routes/items.js` | CRUD behind JWT middleware |
| `application/backend/src/db.js` | `pg` pool from env |
| `application/frontend/src/App.jsx` | UI (login + items) |
| `docker/backend/Dockerfile` | multi-stage, non-root, healthcheck |
| `docker/frontend/Dockerfile` | build stage + nginx stage |
| `docker/nginx/nginx.conf` | SPA + `/api` proxy rules |
| `docker/docker-compose.yml` | full local stack (free, no AWS) |

### Complete code highlights

Backend health route (`src/routes/health.js`) — responded with `200` always so
the ALB health check never flaps on transient DB issues; `/health/ready` is the
strict readiness signal:

```js
router.get("/", async (_req, res) => {
  let dbStatus = "disconnected";
  if (db) {
    try { await db.query("SELECT 1"); dbStatus = "connected"; }
    catch { dbStatus = "disconnected"; }
  }
  res.json({ status: "ok", db: dbStatus, uptime: Math.round(process.uptime()), timestamp: new Date().toISOString() });
});
```

Backend Dockerfile (multi-stage → minimal runtime → non-root):

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY application/backend/package.json application/backend/package-lock.json* ./
RUN npm ci --omit=dev
COPY application/backend/src ./src

FROM node:20-alpine
ENV NODE_ENV=production
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build --chown=appuser:appgroup /app /app
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||'3000')+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]
```

Frontend Dockerfile ends with Nginx (non-root worker) serving the built SPA and
proxying `/api` to `backend:3000`.

### Commands (local, free)

```bash
cd docker
docker compose up --build

# verify in a new terminal
curl -s http://localhost/health
curl -s http://localhost/health/ready
```

### Expected output

```json
{"status":"ok","db":"connected","uptime":12,"timestamp":"2026-08-13T10:00:00.000Z"}
```

### Verification

- `/health` → `202, db: connected`
- Register/login → JWT: `curl -X POST http://localhost/api/auth/register -H 'Content-Type: application/json' -d '{"email":"a@b.c","password":"Password123!"}'`
- CRUD items with `Authorization: Bearer <jwt>`
- `docker compose down` cleans up.

### Common errors

- **Container exits immediately** → check the volume mount/environment
  (`docker logs <name>`). Here the compose stack waits for `db` to be healthy.
- **Backend can't reach DB** → wrong `DB_HOST` (`db`, not `localhost`, inside
  compose networking).

### Security notes

- Backend runs as **non-root** (`appuser`).
- Nginx image runs non-root by default.
- `.dockerignore` keeps `node_modules` and `.env` out of build context.

### Production notes

- `NODE_ENV=production`, `npm ci --omit=dev` → no dev deps in the image.
- Healthchecks are defined for both images so ALB and orchestrators can rely
  on them.

### Beginner explanation

- **Container** = a packaged process with its own filesystem, runnable anywhere.
- **Multi-stage build** = build in a fat image, copy only the runtime essentials
  into a tiny final image.
- **Non-root** = the app runs with limited OS privileges, raising the bar for an
  attacker who exploits it.

### Interview questions

- *"Why multi-stage builds and non-root?"* — smaller attack surface + smaller
  images; no compilers/shells in the runtime image and no root privileges to
  abuse if the process is compromised.

### Phase completion checklist

- [ ] `docker compose up --build` works locally
- [ ] `/health` returns `db: connected`
- [ ] `/api/auth` register/login works
- [ ] Images build as non-root

### Next phase

Phase 13 — ALB + Target Group.

---

# PART D — Compute & Database (13–17)

---

## Phase 13 — ALB + Target Group

### Objective

Create the Application Load Balancer: TLS termination, traffic routing, health
checks.

### Why we need it

With multiple EC2 instances, someone must decide which instance gets each
request, take the TLS load, and stop routing to unhealthy instances. That is
the ALB's job.

### Files

- `terraform/modules/alb/main.tf` (ALB, listeners, target group, health check)

### Complete code (target group = the contract with the app)

```hcl
resource "aws_lb_target_group" "app" {
  name     = "${local.name_prefix}-tg"
  port     = var.app_port          # 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    interval            = var.health_interval
    path                = var.health_check_path   # /health
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = var.health_timeout
    matcher             = "200-299"
  }
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

# The public DNS name you will later curl:
terraform output alb_dns_name
```

### Expected output

```text
secure-ntier-dev-alb-1234567890.ap-south-1.elb.amazonaws.com
```

### Verification

- ALB `state == active`, scheme `internet-facing`.
- Target group created; its health check hits `/health` and matches `200-299`.
- (Listeners are created here too: HTTPS :443 + HTTP→HTTPS redirect when a
  certificate exists — see phase 18 — otherwise plain HTTP :80.)

### Common errors

- **ALB 502** (bad gateway) = targets exist but respond with something the
  health check rejects.
- **ALB 503** = no healthy targets registered at all.

### Security notes

- The ALB is the **only** internet-facing server; its SG only exposes 443/80.
- WAF is attached to the ALB (phase 20).

### Production notes

- `enable_deletion_protection = true` in prod prevents accidental deletion.
- Enable access logs to the S3 bucket in prod for a request audit trail.

### Beginner explanation

- **ALB** = a layer-7 traffic cop: terminates TLS, routes by URL, and only
  sends traffic to instances that pass its health checks.

### Interview questions

- *"What happens if all targets are unhealthy?"* — the ALB returns `503`; the
  ASG (watching the same health signal) launches replacements.

### Phase completion checklist

- [ ] ALB created, internet-facing, in public subnets
- [ ] Target group with `/health` check created
- [ ] `terraform output alb_dns_name` returns a value

### Next phase

Phase 14 — EC2 Launch Template.

---

## Phase 14 — EC2 Launch Template

### Objective

Define the *recipe* for app instances: AMI, size, security group, IAM role,
encryption, IMDSv2, and the boot script that brings up the Docker stack.

### Why we need it

A Launch Template gives every instance identical configuration. Combined with
the IAM instance role, instances are fully serverless-of-secrets: nothing to
store on disk, everything resolved at boot.

### Files

- `terraform/modules/compute/main.tf` (launch template)
- `terraform/modules/compute/user-data.sh` (boot script)

### Complete code highlights

```hcl
resource "aws_launch_template" "this" {
  name          = "${local.name_prefix}-lt"
  image_id      = data.aws_ami.ubuntu.id          # Ubuntu 24.04
  instance_type = var.instance_type              # t3.micro
  iam_instance_profile { arn = aws_iam_instance_profile.instance.arn }
  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    region = var.region, environment = var.environment, ... }))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs { volume_size = var.volume_size; volume_type = "gp3"; encrypted = true }
  }

  metadata_options { http_tokens = "required"; http_put_response_hop_limit = 1 }
}
```

The boot script's flow (see full `user-data.sh`):

```text
install docker + compose + jq
→ ECR login via instance role
→ read image URIs from SSM parameter store
→ read DB credentials from Secrets Manager
→ render docker-compose.yml
→ compose up with retries until healthy
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

(No EC2 instance is launched by the template alone — the ASG does that in
phase 15.)

### Expected output

A launch template resource; no running instances yet.

### Verification

```bash
aws ec2 describe-launch-templates --region ap-south-1
```

### Common errors

- **Template not found by ASG** — ASG references the template by id/name; order
  is handled by Terraform dependency graph.
- **IMDSv2 required breaks old scripts** — realistic; keep `http_tokens=required`.

### Security notes

- EBS encrypted (gp3, `encrypted=true`).
- IMDSv2 *required* — kills SSRF-style credential theft.
- The instance role has only the permissions the boot script needs.

### Production notes

- Ubuntu 24.04 LTS; AMI found by `data "aws_ami"` with `most_recent = true`.
- No SSH key baked in; administration is via SSM Session Manager.

### Beginner explanation

- **Launch template** = a blueprint for an EC2 instance (OS, size, security,
  startup instructions). "Blueprint" vs. "built house".

### Interview questions

- *"How does user-data make instances self-provisioning?"* — the script runs
  once at boot and configures/installs everything, so a fresh instance from the
  template is a running app instance with no manual steps.

### Phase completion checklist

- [ ] Launch template created with Ubuntu 24.04, gp3-encrypted EBS, IMDSv2
- [ ] Template wired to instance role + app SG
- [ ] `user-data.sh` reviewed

### Next phase

Phase 15 — Auto Scaling Group.

---

## Phase 15 — Auto Scaling Group

### Objective

Deploy instances from the launch template across two AZs, keep the desired
count, register them with the ALB, and scale CPU.

### Why we need it

Instances die and load changes. The ASG turns "replace it manually" into
"replace it automatically" — the self-healing core of the platform.

### Files

- `terraform/modules/compute/main.tf` (ASG + scaling policy)

### Complete code (abridged)

```hcl
resource "aws_autoscaling_group" "this" {
  name             = "${local.name_prefix}-asg"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = var.app_subnet_ids   # private app subnets, 2 AZs
  target_group_arns   = [var.target_group_arn]  # register to the ALB

  launch_template { id = aws_launch_template.this.id; version = "$Latest" }

  health_check_type         = "ELB"           # ASG trusts ALB health signal
  health_check_grace_period = 180
  protect_from_scale_in     = true

  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50; instance_warmup = 120 }
  }
}

resource "aws_autoscaling_policy" "cpu" {
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

# Watch it come up
aws autoscaling describe-auto-scaling-groups --region ap-south-1 \
  --query 'AutoScalingGroups[*].{Name:AutoScalingGroupName,Min:MinSize,Desired:DesiredCapacity,Cur:Instances[].InstanceId}'
```

### Expected output

- 2 instances launched (one per AZ).
- Instances registered to the target group and reported `healthy` by the ALB.

### Verification

```bash
# Target health
aws elbv2 describe-target-health --target-group-arn <TG_ARN> --region ap-south-1 \
  --query 'TargetHealthDescriptions[*].{Id:Target.Id,State:TargetHealth.State}'
# Expect: healthy 2x
```

### Common errors

- **Instances keep cycling** — health check fails on the app (check
  `/var/log/user-data.log` on an instance). Fix app/user-data, not the ASG.
- **Scale-in removes the wrong instance** — `protect_from_scale_in = true`
  balances protection.

### Security notes

- Instances land in **private subnets** — the ASG provides no public IPs.
- ASG is the rebalancing + replacement engine; combined with the health check
  this delivers the "failure flow" in [`diagrams/failure-flow.png`](../diagrams/failure-flow.png).

### Production notes

- `InstanceRefresh` config means CI's rolling deploys keep 50% healthy during
  the swap (see phase 21).
- Scale-out via CPU target tracking; scale-in protected.

### Beginner explanation

- **ASG** = a manager that keeps N instances alive, replaces failed ones, and
  scales up/down on demand.

### Interview questions

- *"How does an instance failure get healed without a human?"* — the ALB marks
  it unhealthy; the ASG (health_check_type=ELB) launches a replacement from the
  template; user-data re-provisions it; the ALB re-registers it as healthy.

### Phase completion checklist

- [ ] ASG with min 2 / max 4 / desired 2 across app AZs
- [ ] ASG attached to the target group; `health_check_type=ELB`
- [ ] Both instances healthy in `describe-target-health`
- [ ] CPU target-tracking policy present

### Next phase

Phase 16 — RDS + Secrets Manager.

---

## Phase 16 — RDS PostgreSQL + Secrets Manager

### Objective

Create a managed, encrypted PostgreSQL database in the private DB subnets,
with credentials generated and stored **only** in Secrets Manager.

### Why we need it

The database is the crown jewels. It must be: un-reachable from the internet,
encrypted, backed up, and never carry hardcoded credentials.

### Files

- `terraform/modules/database/main.tf`

### Complete code highlights

```hcl
resource "random_password" "db_password" {
  length = 24; special = true; min_upper = 1; min_lower = 1; min_numeric = 1; min_special = 1
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username   = var.db_username
    password   = random_password.db_password.result
    host       = aws_db_instance.this.address
    port       = aws_db_instance.this.port
    dbname     = var.db_name
    jwt_secret = random_password.jwt_secret.result
  })
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  instance_class = var.db_instance_class          # db.t3.micro
  allocated_storage = var.db_allocated_storage    # 20 GB gp3
  db_name = var.db_name; username = var.db_username
  password = random_password.db_password.result   # stays out of git
  db_subnet_group_name   = aws_db_subnet_group.this.name   # 2 private db subnets
  vpc_security_group_ids = [var.db_sg_id]
  multi_az  = var.db_multi_az                      # false dev / true prod
  backup_retention_period = var.backup_retention_days  # 7
  storage_encrypted = true
  deletion_protection = var.deletion_protection
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

# show the managed endpoint
terraform output db_host        # sensitive (masked unless -raw)
terraform output db_secret_arn
```

### Expected output

- RDS instance `secure-ntier-dev-db` running PostgreSQL, `StorageEncrypted=true`.
- Secrets Manager secret holding `{username,password,host,port,dbname,jwt_secret}`.

### Verification

```bash
aws rds describe-db-instances --region ap-south-1 \
  --query 'DBInstances[*].{Pub:PubliclyAccessible,Enc:StorageEncrypted,MultiAZ:MultiAZ,Class:DBInstanceClass}'
# Expect: Pub=false, Enc=true, MultiAZ=false (dev)
aws secretsmanager get-secret-value --secret-id <ARN> \
  --query SecretString --output text | jq '{username, host}'
```

### Common errors

- **DB connection timeout from app** — app SG must allow 5432 (it does) and DB
  must be in DB subnets with no internet route (it is). Timeout = packet dropped.
- **Password in DIFF** — `random_password` appears in state (encrypted backend),
  not in code. That's why the remote backend is essential.

### Security notes

- DB subnet group = db subnets only; `PubliclyAccessible=false`.
- `storage_encrypted = true` + gp3.
- Credentials auto-rotatable in Secrets Manager; generated per-environment.
- App connects using the secret it retrieves at boot (see user-data).

### Production notes

- Prod: `multi_az=true`, `deletion_protection=true`,
  `skip_final_snapshot=false` (keep a final snapshot on destroy).
- Backups: 7-day retention + point-in-time recovery (see DR doc).

### Beginner explanation

- **RDS** = a managed database service: you get PostgreSQL without running or
  patching servers; backups and failover are handled.
- **Secrets Manager** = a secure vault the app reads at runtime — credentials
  never live in source code.

### Interview questions

- *"How do you get DB credentials into the app without storing them anywhere?"* —
  the app's IAM instance role calls Secrets Manager at boot, gets the JSON, and
  uses it for the connection; rotation can update the secret without code changes.

### Phase completion checklist

- [ ] RDS PostgreSQL running, encrypted, in private DB subnets, `PubliclyAccessible=false`
- [ ] Secret with all runtime credentials in Secrets Manager
- [ ] App instances able to connect (app → db port 5432 allowed)

### Next phase

Phase 17 — Secrets Manager & Parameter Store (runtime configuration).

---

## Phase 17 — Secrets Manager & Parameter Store (runtime configuration)

### Objective

Centralize *all* runtime configuration: DB credentials in Secrets Manager
(secret data) and image "deploy pointers" in SSM Parameter Store
(non-secret).

### Why we need it

- **Secrets** (password, jwt) → Secrets Manager (encrypted, rotational).
- **Configuration** (which image tag is live) → SSM Parameter Store (cheap,
  versionable, right-sized for a URL).

### Files

- `terraform/modules/database/main.tf` — secrets (phase 16)
- `terraform/modules/compute/main.tf` — SSM parameters (below)

### Complete code (SSM deploy pointers)

```hcl
resource "aws_ssm_parameter" "backend_image" {
  name  = "/secure-ntier/${var.environment}/backend-image"
  type  = "String"
  value = var.initial_backend_image
}
resource "aws_ssm_parameter" "frontend_image" {
  name  = "/secure-ntier/${var.environment}/frontend-image"
  type  = "String"
  value = var.initial_frontend_image
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

aws ssm get-parameter --name "/secure-ntier/dev/backend-image" --region ap-south-1 \
  --query Parameter.Value
```

### Expected output

The SSM parameter holds the current image URI (empty at first apply, set by CI
in phase 21). The secret (phase 16) holds credentials.

### Verification

- `ssm get-parameter` returns the parameter.
- `secretsmanager get-secret-value` returns `{username,password,host,port,dbname,jwt_secret}`.

### Common errors

- **Secrets in Terraform vars** — never put a literal password in
  `terraform.tfvars`. Use generated `random_password` values stored in the
  Secrets Manager secret (phase 16).

### Security notes

- The instance role can read exact SSM params and the one secret; nothing else.
- SSM params are non-sensitive (image URLs); all credentials live in Secrets
  Manager.

### Production notes

- The SSM parameter pattern gives **immutable deployments**: the image URL is a
  versioned pointer; changing it and refreshing the ASG = the whole deploy.

### Beginner explanation

- **Parameter Store** = a small key-value config store (image URLs, flags).
  **Secrets Manager** = the vault for passwords/tokens with rotation.

### Interview questions

- *"What is an immutable deployment?"* — instances never update in place; you
  change the image pointer (SSM param) and launch fresh instances from the new
  image via instance refresh.

### Phase completion checklist

- [ ] SSM params for both image pointers exist
- [ ] Secrets Manager holds all runtime credentials
- [ ] Instance role has exact read permissions for both (phase 04 check)

### Next phase

Phase 18 — HTTPS / ACM.

---

# PART E — DNS, TLS, WAF, CI/CD (18–21)

---

## Phase 18 — HTTPS / ACM Certificate

### Objective

Provision a TLS certificate (ACM) for your domain and wire it into the ALB
listener so traffic is encrypted end-to-end.

### Why we need it

No password or token should cross the internet in plain text. HTTPS via ACM + a
free certificate is the standard.

### Files

- `terraform/main.tf` (ACM resources + Route 53 validation record)

### Complete code

```hcl
data "aws_route53_zone" "selected" {
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}
```

The ALB module then uses `certificate_arn` on the 443 listener and adds a
301 redirect 80→443 (see `terraform/modules/alb/main.tf`).

### Commands

```bash
# set domain_name in terraform/environments/dev/terraform.tfvars
#   domain_name = "app.example.com"
terraform apply -var-file="environments/dev/terraform.tfvars"

# certificate should become ISSUED within a few minutes
aws acm list-certificates --region ap-south-1 \
  --query 'CertificateSummaryList[*].{Domain:CertificateDomainName,Status:CertificateArn}'
aws acm describe-certificate --certificate-arn <ARN> --query 'Certificate.Status'
```

### Expected output

```text
Certificate.Status == "ISSUED"
```

plus an ALB listener on `:443` using the certificate and `:80` redirecting.

### Verification

```bash
curl -sI https://app.example.com/health | head -3
# HTTP/2 200 ... via HTTPS (certificate valid, no warnings)
```

### Common errors

- **Pending validation forever** — DNS validation record not propagating
  (check Route 53; ensure the zone really owns the name).
- **`Region = us-east-1`** — certificates must be requested in the **same
  region as the ALB** (except CloudFront, which requires us-east-1).

### Security notes

- TLS 1.2+ enforced via the listener's `ssl_policy`.
- ACM renews automatically; you never manage private keys.

### Production notes

- Use a wildcard cert only if multiple subdomains share one ALB; otherwise keep
  exact-name certs.
- Route 53 alias record `app.example.com → ALB` is created in phase 19.

### Beginner explanation

- **TLS/SSL** encrypts traffic so eavesdroppers only see ciphertext.
- **ACM** = AWS's free certificate authority; it also auto-renews.

### Interview questions

- *"DNS validation vs email validation for ACM?"* — DNS is automated: Terraform
  writes the validation record and ACM completes; no manual email clicks.

### Phase completion checklist

- [ ] Certificate `ISSUED` in the app region
- [ ] HTTPS listener using the certificate
- [ ] HTTP → HTTPS redirect

### Next phase

Phase 19 — Route 53 DNS.

---

## Phase 19 — Route 53 (DNS)

### Objective

Point your domain at the ALB with an alias record and enable health-check-based
behavior.

### Why we need it

Users type `app.example.com`, not the ALB's random DNS name. Route 53 maps the
name to the ALB alias (and can fail over if integrated with health checks).

### Files

- `terraform/main.tf` (`aws_route53_record.app`)

### Complete code

```hcl
resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

dig +short app.example.com          # or: nslookup app.example.com
```

### Expected output

```text
secure-ntier-dev-alb-1234567890.ap-south-1.elb.amazonaws.com.
```

### Verification

- `dig` / `nslookup` resolves your domain to the ALB DNS name.
- `curl -sI https://app.example.com/health` returns `200`.

### Common errors

- **Name not resolving** — the hosted zone must exist and own the domain (or a
  subdomain with delegation/NS records pointing to it).
- **Alias zone mismatch** — the hosting zone for `app.example.com` must be the
  one passed to the record.

### Security notes

- An alias record with `evaluate_target_health=true` lets Route 53 stop
  answering with an unhealthy LB (optional phased behavior in prod).

### Production notes

- Separate hosted zones per environment keep prod DNS isolated from dev.

### Beginner explanation

- **DNS** = the phonebook of the internet: it turns a name into an address.
- **Alias record** = Route 53's special record that tracks the ALB automatically.

### Interview questions

- *"Alias vs A record?"* — Alias is native to Route 53, free, and updates
  automatically when the ALB changes; a CNAME/A requires manual update.

### Phase completion checklist

- [ ] `app.example.com` resolves to ALB via alias record
- [ ] HTTPS is reachable through the domain

### Next phase

Phase 20 — AWS WAF.

---

## Phase 20 — AWS WAF

### Objective

Associate a Web Application Firewall with the ALB, using AWS-managed rules to
block common web attacks before they reach the app.

### Why we need it

Web apps get attacked. WAF stops the noise (SQLi, XSS, bad bots, known bad IPs)
in front of the ALB, so the app only ever sees clean traffic — and the cloud
watch logs prove it.

### Files

- `terraform/modules/alb/main.tf` (`aws_wafv2_web_acl` + association)

### Complete code (rule groups added)

```hcl
resource "aws_wafv2_web_acl" "this" {
  name = "${local.name_prefix}-waf"
  scope = "REGIONAL"
  default_action { allow {} }

  rule {
    name = "AWSManagedRulesCommonRuleSet"; priority = 1
    override_action { none {} }
    statement { managed_rule_group_statement {
      name = "AWSManagedRulesCommonRuleSet"; vendor_name = "AWS" } }
    visibility_config { cloudwatch_metrics_enabled = true
      metric_name = "${local.name_prefix}-common"; sampled_requests_enabled = true }
  }
  # ... SQLiRuleSet (2), AmazonIpReputationList (3)
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

aws wafv2 list-web-acls --scope REGIONAL --region ap-south-1 \
  --query 'WebACLs[*].{Id:Id,Name:Name}'
```

### Expected output

```text
secure-ntier-dev-waf
```

### Verification

1. `aws wafv2 get-web-acl` shows the three managed rule groups.
2. **Attack test** — send a SQLi payload and expect a block:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  "http://<ALB_DNS>/api/items?filter=1%27%20OR%20%271%27%3D%271"
curl -s -o /dev/null -w "%{http_code}\n" \
  "http://<ALB_DNS>/api/items?filter=<script>alert(1)</script>"
# Expect 403 with the WAF block page (SQLi / XSS flagged)
```

3. Normal traffic still works: `curl -s http://<ALB_DNS>/health` → `200`.

### Common errors

- **403 to legitimate traffic** — a managed rule is over-matchy; set
  `override_action` or the rule action to `count` (measure) before blocking in
  production, or add an IP-based allow rule for known crawlers on the allowlist.

### Security notes

- Managed rules are maintained by AWS so protections stay current without your
  teams writing signatures.
- WAF is **before** the app: it also shields misconfigurations and
  slow-to-patch timeframes.
- Sampled requests + CloudWatch metrics are enabled so blocking is observable.

### Production notes

- Layer additional rules (rate limiting, geo) for specific threats.
- Keep WAF integration tested in CI (security-tests call the ALB with bad
  payloads).

### Beginner explanation

- **WAF** = a bouncer at the club door; it checks each request against known
  attack patterns before the bouncer at the app level even sees it.

### Interview questions

- *"Why WAF in front of the ALB (and not the app)?"* — filtering at the edge
  protects every instance and offloads the app; the app receives only vetted
  traffic.

### Phase completion checklist

- [ ] WAF web ACL created with managed rule groups
- [ ] WAF associated with the ALB
- [ ] SQLi / XSS test payloads blocked (403), normal traffic passes (200)

### Next phase

Phase 21 — CI/CD Pipeline.

---

## Phase 21 — CI/CD Pipeline (GitHub Actions)

### Objective

Automate: push → validate manifest → test → scan → build images → push to ECR
→ update deploy pointers → rolling instance refresh → smoke test. Fail the
pipeline on any critical issue.

### Why we need it

Manual deploys are slow, inconsistent, and error-prone. A pipeline makes every
`main` push a *candidate release* that travels the same verified path — with
security gates that stop bad code.

### Architecture

See [`diagrams/cicd.png`](../diagrams/cicd.png). The pipeline is
**manifest-driven**: every stage loops over `stack.json` (services, toolchain,
`ci_steps`, ports), so a new service needs **only a `stack.json` entry**.

### Files

| File | Purpose |
| ---- | ------- |
| `stack.json` | The manifest: services, ports, toolchains, `ci_steps`, db engine/version, runtimes |
| `cicd/scripts/stack-validate.sh` | Validate the manifest in CI |
| `cicd/scripts/stack-ci.sh` | CI for every service: ci_steps in toolchain container → docker build → trivy scan |
| `cicd/scripts/stack-push.sh` | Build + push every service to ECR (`:sha` + `:latest`) |
| `.github/workflows/ci.yml` | CI: manifest validate → per-service CI → terraform validate |
| `.github/workflows/deploy.yml` | CD: ECR push → update SSM → instance refresh → smoke test |
| `cicd/scripts/deploy-ec2.sh` | update SSM params (per service) + start instance refresh |
| `cicd/scripts/smoke-test.sh` | wait for healthy app via ALB |
| `cicd/Jenkinsfile` / `cicd/Jenkinsfile-ci` | The same pipelines for the optional Jenkins engine |

### Required GitHub Secrets

| Secret | Value |
| ------ | ----- |
| `AWS_ACCESS_KEY_ID` | CI/CD IAM user key |
| `AWS_SECRET_ACCESS_KEY` | CI/CD IAM user secret |
| `AWS_REGION` | e.g. `ap-south-1` |
| `ALB_URL` | `http://<ALB_DNS>` (or `https://app.example.com`) |
| `ECR_PROJECT` | `secure-ntier` |
| `ECR_ENV` | `dev` |

### Complete code (deploy stages, abridged)

```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Backend tests
        working-directory: application/backend
        run: |
          npm ci
          npm test
          npm audit --audit-level=high

      - name: Login to ECR
        run: bash cicd/scripts/ecr-login.sh "${{ secrets.AWS_REGION }}"

      - name: Build + push backend image
        run: bash cicd/scripts/build-and-push.sh backend "${{ github.sha }}" "${{ secrets.AWS_REGION }}" "${{ secrets.ECR_PROJECT }}" "${{ secrets.ECR_ENV }}"

      - name: Build + push frontend image
        run: bash cicd/scripts/build-and-push.sh frontend "${{ github.sha }}" "${{ secrets.AWS_REGION }}" "${{ secrets.ECR_PROJECT }}" "${{ secrets.ECR_ENV }}"

      - name: Trivy scan images   # fail on CRITICAL/HIGH
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: "${{ secrets.ECR_PROJECT }}-${{ secrets.ECR_ENV }}-backend:${{ github.sha }}"
          exit-code: 1
          severity: CRITICAL,HIGH

      - name: Update deploy params + trigger instance refresh
        run: bash cicd/scripts/deploy-ec2.sh "${{ github.sha }}" "${{ secrets.AWS_REGION }}" "${{ secrets.ECR_ENV }}" "${{ secrets.ECR_PROJECT }}"

      - name: Smoke test
        env: { ALB_URL: ${{ secrets.ALB_URL }}, ATTEMPTS: "36" }
        run: bash cicd/scripts/smoke-test.sh
```

### Commands

```bash
# configure secrets in GitHub → Settings → Secrets and variables → Actions
# then simply push:
git push origin main
```

### Expected output

Deploy workflow passes end-to-end:

```text
Checkout → stack-validate → CI per service (tests + build + trivy) → ECR push
→ SSM params → instance refresh → smoke ✓
```

### Verification

- `github.com/<you>/<repo>/actions` shows a **green** deploy run.
- `aws ssm get-parameter --name /secure-ntier/dev/backend-image` now returns
  `<ACCOUNT>.dkr.ecr.<region>.amazonaws.com/secure-ntier-dev-backend:<sha>`.
- `curl -s http://<ALB_DNS>/health` returns `200` + `db: connected`.

### Common errors

- **Pipeline can't auth to AWS** — CI user lacks the `cicd-policy`;
  attach `terraform output cicd_policy_arn` and/or manually attach
  `security/iam/cicd-policy.json`.
- **Trivy kills the pipeline** — a HIGH/CRITICAL exists; fix the dependency or
  (for triage only) adjust `severity` — the correct fix is upgrading the package.
- **Smoke test times out** — the instance refresh took > the wait; check
  `aws autoscaling describe-auto-scaling-groups` refresh status and ALB health.

### Security notes

- The pipeline uses long-lived access keys here; **production upgrade**: GitHub
  Actions **OIDC** so no secrets are stored at all (see future improvements).
- Trivy + npm audit gate the release — critical/high findings stop the deploy.

### Production notes

- Uses *immutable image tags* (`github.sha`) + SSM pointer + instance refresh
  = rolling, zero-command deploys with 50% availability during the swap.

### Beginner explanation

- **CI/CD** = when you push code, a robot (GitHub Actions) checks, tests,
  scans, packages, ships, and verifies it automatically.
- **Instance refresh** = the ASG replaces instances one by one so new code is
  live without downtime.

### Interview questions

- *"How do you deploy a new image to EC2 without SSH?"* — the CI pipeline
  pushes `image:sha` to ECR, writes the new URI into SSM params, and starts a
  rolling ASG instance refresh; user-data on fresh instances pulls the new
  images and boots them.

### Phase completion checklist

- [ ] GitHub secrets configured
- [ ] `git push origin main` runs a green deploy
- [ ] SSM params updated with the new image tags
- [ ] Smoke test passed (ALB serves the new build)

### Next phase

Phase 22 — Monitoring.

---

# PART F — Observability & Ops (22–28)

---

## Phase 22 — Monitoring (CloudWatch Alarms + SNS)

### Objective

Collect metrics from EC2/ALB/RDS/ASG, fire alarms on meaningful thresholds,
and notify ops by email.

### Why we need it

"I found out when the users complained" is unacceptable. Alarms detect drift
(CPU, 5xx, unhealthy hosts, DB storage) and page the team *before* an outage.

### Architecture

```text
Metric → CloudWatch Alarm → SNS Topic → Email / pager
```

### Files

- `terraform/modules/monitoring/main.tf`

### Complete code (alarm examples)

```hcl
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_high_threshold          # 70
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = { AutoScalingGroupName = var.asg_name }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"
  threshold   = 0            # one is too many
  alarm_actions = [aws_sns_topic.alerts.arn]
  dimensions = { LoadBalancer = local.alb_suffix; TargetGroup = local.tg_suffix }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  metric_name = "FreeStorageSpace"
  namespace   = "AWS/RDS"
  comparison_operator = "LessThanThreshold"
  threshold = var.db_allocated_storage_gb * 1024 * 1024 * 1024 * 0.2   # < 20%
  alarm_actions = [aws_sns_topic.alerts.arn]
  dimensions = { DBInstanceIdentifier = var.db_instance_id }
}
```

Plus top-level alarms for **ALB 5xx**, **RDS CPU**, and a CloudWatch dashboard
(`terraform/modules/monitoring/main.tf`).

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

# list alarms
aws cloudwatch describe-alarms --region ap-south-1 \
  --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue}'
```

### Expected output

```text
secure-ntier-dev-asg-cpu-high
secure-ntier-dev-alb-target-5xx
secure-ntier-dev-alb-unhealthy-hosts
secure-ntier-dev-rds-cpu-high
secure-ntier-dev-rds-storage-low
```

### Verification

- Confirm email — you must **confirm the SNS subscription** (click the link in
  the email) before alarms can notify you.
- Trigger test: produce a 5xx (e.g. `curl http://<ALB_DNS>/does-not-exist` won't
  5xx; simulate by stopping the container briefly) and watch the alarm
  transition to `IN ALARM`.

### Common errors

- **No notifications despite alarm** — SNS subscription not confirmed; check
  `aws sns list-subscriptions-by-topic`.

### Security notes

- Alarm thresholds chosen so *noise* is low but *failure* is caught: CPU > 70%
  for 10 min, any unhealthy host, 5xx bump, RDS storage < 20%.

### Production notes

- Add a dashboard (`monitoring/dashboards/overview-dashboard.json` + the
  `aws_cloudwatch_dashboard` resource) for the on-call view.

### Beginner explanation

- **CloudWatch** = AWS's metric/log service. **Alarm** = a rule ("if X then
  notify"). **SNS** = the notification service ("email me").

### Interview questions

- *"How do you turn metrics into people?"* — metric → alarm (threshold +
  evaluation periods) → SNS topic → email/SMS; dashboard for humans, alarms for
  machines.

### Phase completion checklist

- [ ] SNS topic + confirmed email subscription
- [ ] 5 alarms created (CPU, 5xx, unhealthy hosts, RDS CPU, RDS storage)
- [ ] Dashboard visible in CloudWatch

### Next phase

Phase 23 — Logging (CloudTrail, Flow Logs, app logs).

---

## Phase 23 — Logging (CloudTrail, Flow Logs, application)

### Objective

Collect audit + application logs so incidents are attributable and debuggable.

### Why we need it

Without logs, a security event or bug is invisible. CloudTrail logs AWS API
actions; Flow Logs log network traffic; the app writes its own logs to
CloudWatch Logs.

### Files

- `terraform/main.tf` — CloudTrail + its S3 bucket
- `terraform/modules/vpc/main.tf` — VPC Flow Logs (phase 10)
- `terraform/modules/compute/main.tf` — instance role grants
  `logs:CreateLogStream` / `PutLogEvents`
- `terraform/modules/compute/user-data.sh` — container drivers `awslogs`

### Complete code (CloudTrail + bucket)

```hcl
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail"
  force_destroy = true
}
# + server-side encryption + bucket policy granting CloudTrail PutObject/GetBucketAcl

resource "aws_cloudtrail" "this" {
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
}
```

App logging in `user-data.sh` (containers use the `awslogs` driver):

```text
backend:  awslogs-group = /secure-ntier-{env}/app  awslogs-stream-prefix = backend
frontend: awslogs-group = /secure-ntier-{env}/app  awslogs-stream-prefix = frontend
```

### Commands

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"

aws cloudtrail get-trail-status --name secure-ntier-dev-trail --region ap-south-1
aws logs describe-log-groups --region ap-south-1 \
  --query 'logGroups[*].{Group:logGroupName}'
```

### Expected output

- CloudTrail trail active (`IsLogging: true`).
- Log groups present: `/aws/vpc-flow-log/secure-ntier-dev`,
  `/secure-ntier-dev/app`.

### Verification

```bash
aws logs filter-log-events --log-group-name /secure-ntier-dev/app \
  --filter-pattern "ERROR" --region ap-south-1 --limit 5
```

(Returns app error logs after the app has run.)

### Common errors

- **No app logs** — instances lack the `logs:*` permission or the container
  `awslogs` region; check the instance role + compose `logging:` block.

### Security notes

- CloudTrail logs every management API call (who did what) — investigations
  start here.
- Flow Logs capture accepted/rejected network flows — security-test proof.
- Log groups access is IAM-scoped; only the instance role write-scope is granted.

### Production notes

- Route expensive application logs (request bodies, PII) with filters; storage
  retention set per environment (14d dev / 90d prod).

### Beginner explanation

- **CloudTrail** = an audit diary of AWS API calls.
- **Logs** = text diaries your application writes; CloudWatch Logs stores and
  searches them.

### Interview questions

- *"Which 3 log sources does this platform keep?"* — CloudTrail (management
  API), VPC Flow Logs (network), application logs (awslogs driver to
  CloudWatch).

### Phase completion checklist

- [ ] CloudTrail active and multi-region
- [ ] VPC Flow Logs writing to CloudWatch
- [ ] App + nginx logs appearing in `/secure-ntier-dev/app`

### Next phase

Phase 24 — Security Testing.

---

## Phase 24 — Security Testing

### Objective

Prove the security controls actually work — programmatically, via
`tests/security/security-tests.sh`.

### Why we need it

Security is only real if verified. These tests check the *outside* (is the DB
public? ports open? HTTPS on?) and the *inside* (WAF blocks, IAM scoping, no
secrets anywhere).

### Files

- `tests/security/security-tests.sh`

### What it checks (abridged)

| # | Test | Expected |
| - | ---- | -------- |
| 1 | RDS `PubliclyAccessible` | `false` |
| 2 | EC2 instances have **no public IP** | none |
| 3 | ALB SG exposes only 80/443 | no 22/3389 etc. |
| 4 | DB SG allows 5432 only from app SG | set |
| 5 | HTTPS reachable on `:443` | `200` |
| 6 | WAF associated with ALB | web ACL ARN == attached |
| 7 | SSH/3389 blocked from internet | `0` open |
| 8 | Secrets (passwords/keys) not in git | `rg` scan finds none |
| 9 | WAF blocks SQLi / XSS payloads | `403` |
| 10 | No `FullAccess / "*"` on app/CICD roles | policy review |

### Commands

```bash
cd tests/security
bash security-tests.sh --region ap-south-1 --alb-url http://<ALB_DNS>
```

### Expected output

```text
[PASS] RDS is not publicly accessible
[PASS] EC2 instances have no public IP
[PASS] ALB exposes only 80/443
[PASS] WAF is attached to the ALB
[PASS] SQLi payload blocked (403)
[PASS] secrets not present in repository
...
Summary: 10 passed, 0 failed
```

### Verification

Every check must print `[PASS]`. Any failure is a phase-stop: fix the control,
not the test.

### Common errors

- **`pg_isready` from your laptop to the DB hangs** — that's *correct*: the DB
  is private; the test asserts the SG/subnet result, not direct connectivity.

### Security notes

- These tests mirror the SRE "trust but verify" principle: the design claims
  are executed and asserted, not assumed.
- Run them in CI as part of a **security gate** in production.

### Beginner explanation

- **Security testing** = automated checks that say "yes, the door is still
  locked" — we don't trust the design, we test the build.

### Interview questions

- *"How would you prove the database is not exposed?"* — assert
  `PubliclyAccessible=false`, check the SG rules, and try a connection from the
  internet (timeout = dropped). Then test again after every change.

### Phase completion checklist

- [ ] All checks `[PASS]`
- [ ] WAF block test (SQLi/XSS → 403) passes
- [ ] Secret scan finds nothing in the repo

### Next phase

Phase 25 — Application & Infrastructure Testing.

---

## Phase 25 — Application & Infrastructure Testing

### Objective

Verify the application logic (unit/API/integration) and the Terraform build
(validate, plan sanity).

### Why we need it

Automated tests make refactoring safe and catch regressions days before a user
does.

### Files

- `application/backend/test/*.test.js` — route/controller tests
- `tests/application/integration.sh` — endpoint tests against a running stack
- `tests/integration/e2e.sh` — end-to-end flow (register → login → CRUD)
- `tests/infrastructure/terraform-validate.sh` — `terraform validate` in CI
- `tests/infrastructure/tfplan-check.sh` — plan sanity (subnet count, SGs, ALB, RDS…)

### Commands

```bash
# Application unit/API tests (run locally too)
cd application/backend && npm test

# Infrastructure tests (from ci, also runnable locally)
bash tests/infrastructure/terraform-validate.sh
bash tests/infrastructure/tfplan-check.sh

# Integration against a running stack
bash tests/application/integration.sh --base-url http://localhost
```

### Expected output

```text
backend tests ............ 12 passing
frontend build ........... compiled
integration suite ........ register/login/items ............ 3 passing
terraform validate ....... Success! The configuration is valid.
tfplan-check ............. subnets=6 sgs=3 alb=1 rds=1 asg=1 ... ok
```

### Verification

- All unit + integration tests pass.
- `terraform validate` clean; `tfplan-check` asserts the resource counts you
  expect.

### Common errors

- **Test mocks drift from real DB schema** — integration tests run against the
  real compose DB to catch this.
- **`npm test` needs a DB** — the suite uses `app.factory` DI to inject a fake
  DB for unit tests; integrations need `docker compose up` first.

### Security notes

- Tests never require real credentials; `/health` is the neutral canary.
- Integration tests run against dev only — never write to prod data.

### Beginner explanation

- **Unit test** = test one small function in isolation. **Integration test** =
  test several pieces talking to each other for real.

### Interview questions

- *"Unit vs integration vs E2E, what's in this repo?"* — unit (route logic with
  injected fake DB), integration (`/health`, auth, items over HTTP to a live
  compose stack), E2E (full register→login→CRUD against the AWS deployment).

### Phase completion checklist

- [ ] `npm test` green (backend)
- [ ] Frontend builds in CI
- [ ] Integration suite green against local compose
- [ ] Terraform validate + plan checks green

### Next phase

Phase 26 — Failure / Chaos Testing.

---

## Phase 26 — Failure (Chaos) Testing

### Objective

Deliberately break things to prove the platform heals itself.

### Why we need it

Self-healing claims are only real if demonstrated. This phase runs the exact
scenarios from the runbooks on the live dev environment.

### Failure tests

**Test 1 — Kill an EC2 instance (ASG replace).**

```bash
aws autoscaling describe-auto-scaling-groups --region ap-south-1 \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId'

aws ec2 terminate-instances --instance-ids <INSTANCE_ID> --region ap-south-1

# watch the ASG replace it
aws autoscaling describe-auto-scaling-groups --region ap-south-1 \
  --query 'AutoScalingGroups[0].{Instances:Instances[].InstanceId,Healthy:Instances[].HealthStatus}'
```

Expected: a new instance appears within minutes; app remains up (the other AZ's
instance + ALB covered it).

**Test 2 — Stop the app container (health check catches it).**

```bash
# SSM into an instance then:
docker stop secure-ntier-dev-backend   # (or: docker compose -f /opt/app/docker-compose.yml stop backend)
```

Expected: ALB health check `/health` fails, instance marked unhealthy, ASG
replaces it. `docker-compose.yml` uses `restart: unless-stopped` so even the
container itself restarts.

**Test 3 — Send invalid traffic (WAF block).**

```bash
curl -s -o /dev/null -w "%{http_code}\n" "http://<ALB_DNS>/api/items?filter=<script>alert(1)</script>"
```

Expected: `403`.

### Verification

- After each test, the stack returns to all-healthy with no manual action.
- CloudWatch alarms / logs capture the incident trail.

### Common errors

- **ASG didn't replace** — check ASG `health_check_type=ELB` and that ELB
  health actually fails (`describe-target-health`); the grace period can mask a
  slow start.

### Security notes

- Chaos tests run in **dev only**; never against prod without a full green run
  and alerting permission.

### Production notes

- Automate with a chaos job (`aws autoscaling start-instance-refresh` is the
  kind, low-impact variation), and keep a runbook per scenario (see `docs/runbooks/`).

### Beginner explanation

- **Chaos testing** = break things on purpose, in a safe environment, to learn
  how the system behaves under failure before real production failure.

### Interview questions

- *"What's your failure test matrix?"* — instance termination (ASG replaces),
  container death (health check + restart policy), bad traffic (WAF 403), DB
  connection loss (alarms), and ASG refresh (rolling).

### Phase completion checklist

- [ ] instance-termination test passed (auto replacement)
- [ ] container-stop test passed (health check triggers recovery)
- [ ] WAF 403 test passed
- [ ] All systems return to `healthy` without human intervention

### Next phase

Phase 27 — Disaster Recovery.

---

## Phase 27 — Disaster Recovery

### Objective

Define RTO / RPO and make recovery a drilled, testable procedure — not hope.

### Why we need it

"Backups exist" isn't a DR plan. A DR plan states *how fast* (RTO) and *how
much data loss is acceptable* (RPO), and the steps to rebuild everything.

### Architecture

See [`diagrams/disaster-recovery.png`](../diagrams/disaster-recovery.png).

### Recovery targets

| Metric | Definition | This platform |
| ------ | ---------- | ------------- |
| **RTO** | time to restore service | < 60 min (IaC + snapshots) |
| **RPO** | max acceptable data loss | ~5 min (RDS point-in-time recovery) |

### Recovery procedures

**A) Database loss**

```bash
# find the latest snapshot
aws rds describe-db-snapshots --db-instance-identifier secure-ntier-dev-db \
  --query 'DBSnapshots[-1].DBSnapshotIdentifier'

# restore (then point the app at the new endpoint)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier secure-ntier-dev-db-restored \
  --db-snapshot-identifier <SNAPSHOT_ID> \
  --db-subnet-group-name secure-ntier-dev-db-subnet-group \
  --vpc-security-group-ids <DB_SG_ID>
```

Then swap the app secret's `host` (Secrets Manager) and it reconnects.

**B) Full infrastructure loss (region/AZ)**

```bash
# state is safe in S3 + DynamoDB (phase 05)
terraform init -backend-config="environments/dev/backend.hcl"
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

Then re-push images / re-trigger the pipeline (ECR keeps images).

**C) Credential rotation**

```bash
aws secretsmanager rotate-secret --secret-id secure-ntier-dev-db-credentials \
  --rotation-lambda-arn ...   # or rotate manually on the RDS + update secret
```

### Verification

- **DR drill**: restore a snapshot into a scratch instance and prove data;
  or `terraform apply` a pristine environment from state and hit `/health`.
- Document the drill in [`docs/architecture/disaster-recovery.md`](./architecture/disaster-recovery.md) and
  [`docs/operations/backup.md`](./operations/backup.md).

### Common errors

- **Recovered DB has a new endpoint** — the app must point to it; that's why
  `host` lives in the secret and the app reads it at boot (no code change).

### Security notes

- Snapshots are encrypted (default for encrypted instances); keep them private.
- Restored DB must use the DB security group — no public access ever.

### Beginner explanation

- **RTO** = how quickly the business is back. **RPO** = how much recent data is
  acceptable to lose. Everything here aims at: minutes, not days.

### Interview questions

- *"What is your RPO?"* — ~5 minutes thanks to RDS point-in-time recovery.
- *"What is your RTO?"* — under an hour, because Terraform state + ECR images
  let us rebuild the whole stack and redeploy without manual setup.

### Phase completion checklist

- [ ] RTO/RPO targets written down
- [ ] Snapshot restore procedure tested
- [ ] Full rebuild from Terraform state tested

### Next phase

Phase 28 — Documentation & Runbooks.

---

## Phase 28 — Documentation & Runbooks

### Objective

Write the operating manual: architecture, deployment, troubleshooting, and
step-by-step runbooks for every believable incident.

### Why we need it

The platform runs 24/7; the humans do not. On-call engineers need precise,
verifiable playbooks, not tribal knowledge.

### Files

| Art | Where |
| --- | ----- |
| Architecture (overview/network/security/cicd/monitoring/DR) | `docs/architecture/` |
| Deployment (prereq, aws-setup, terraform, app, cicd) | `docs/deployment/` |
| Operations (monitoring, backup, scaling, troubleshooting) | `docs/operations/` |
| Runbooks (deployment-failure, instance-failure, db-failure, rollback) | `docs/runbooks/` |
| ADRs 001–008 | `docs/adr/` |
| Testing / Cost / Interview | `docs/testing.md`, `docs/cost-guide.md`, `docs/interview-questions.md` |
| Diagrams | `diagrams/` (Mermaid) |
| Screenshot instructions | `screenshots/README.md` |

### Runbook format

Each runbook (`docs/runbooks/*.md`) follows:

```text
Purpose → When to use → Prerequisites → Symptoms → Diagnosis
→ Commands → Recovery → Verification → Escalation → Post-incident
```

### Commands

None (documentation written in `docs/`).

### Expected output

A reader who has never seen the project can, from docs alone: rebuild it,
deploy it, and resolve an incident.

### Verification

**The "bus-factor" test**: hand a teammate (or yourself in 3 weeks) the docs and
ask them to deploy + respond to one incident. If they had to invent steps, the
docs failed — fix them.

### Common errors

- **Docs drift from code** — every code change updates the matching doc; the
  diagrams are tied to the Terraform modules (see `diagrams/README.md`).

### Security notes

- Never put secrets or real endpoints in docs — use placeholders like
  `<ACCOUNT_ID>`, `<ALB_DNS>`.

### Beginner explanation

- **Runbook** = a checklist for handling an incident written *while calm*, so
  it can be followed *while panicked*.

### Interview questions

- *"What's in a good runbook?"* — a clear trigger, symptoms, diagnosis commands,
  step-by-step recovery, verification, escalation path, and a post-incident
  review note.

### Phase completion checklist

- [ ] All referenced docs exist and link correctly
- [ ] Runbooks for deploy/instance/db/rollback present
- [ ] Docs pass the "bus-factor" test

### Next phase

Phase 29 — Final Validation.

---

## Phase 29 — Final Validation (Production Readiness)

### Objective

Run the complete production-readiness checklist against a live environment.

### Why we need it

A platform is only finished when every claim is *verified*, not just written.

### Production Readiness Checklist

```text
[ ] Terraform validated             → terraform validate = Success
[ ] Terraform plan reviewed         → plan has no surprises
[ ] Infrastructure deployed         → apply completed cleanly
[ ] VPC verified                    → describe-vpcs
[ ] Subnets verified                → 6 subnets, 3 tiers × 2 AZs
[ ] Routes verified                 → public→IGW, app→NAT, db→none
[ ] Security groups verified        → ALB→App→DB, no SSH
[ ] NACL verified                   → per-tier deny-by-default
[ ] Flow logs active                → describe-flow-logs ACTIVE
[ ] ALB verified                    → healthy targets
[ ] EC2 verified                    → 2 healthy instances
[ ] Auto Scaling verified           → ASG min/desired/max
[ ] RDS verified                    → encrypted, private, backups
[ ] ECR verified                    → both repos, scan_on_push
[ ] Docker verified                 → local compose + images build
[ ] Application verified            → `/health` = 200, db connected
[ ] HTTPS verified                  → curl -I https:// returns 200 (if domain)
[ ] Route 53 verified               → dig resolves to ALB (if domain)
[ ] WAF verified                    → SQLi/XSS = 403, normal = 200
[ ] IAM verified                    → least-privilege audit
[ ] Secrets Manager verified        → secret exists, retrievable, no code leak
[ ] CloudWatch verified             → 5 alarms + dashboard
[ ] CloudTrail verified             → trail active
[ ] CI/CD verified                  → green pipeline on push
[ ] Security tests passed           → security-tests all PASS
[ ] Failure tests passed            → chaos tests recovered
[ ] Backup verified                 → snapshot exists
[ ] Recovery tested                 → DR drill passed
[ ] Documentation completed         → docs link-check passes
[ ] Cleanup procedure tested        → terraform destroy works
```

### The one-command verification

```bash
bash scripts/verify.sh ap-south-1 secure-ntier dev http://<ALB_URL>
```

(expected output: a checklist summary of the environment.)

### Unexpected result

Any `[ ]` is a blocker — resolve it before calling the platform done.

### Production notes

For a real go-live, additionally: enable `multi_az=true`,
`deletion_protection=true`, OIDC instead of access keys, higher RDS class,
WAF rate-limit rules, and a second region (DR site).

### Next phase

Phase 30 — Kubernetes (EKS).

---

## Phase 30 — Kubernetes (EKS)

### Objective

Deploy the same application on a managed Kubernetes cluster (Amazon EKS) with
full CI/CD - as a modern alternative that coexists with the EC2 path.

### Why we need it

Container orchestration gives us declarative desired state, native rolling
updates, pod-level auto-scaling, and a clean rollback story (`kubectl rollout
undo`) - capabilities that Docker Compose on EC2 lacks.

### Prerequisites

- EC2 + RDS stack applied (the EKS cluster reuses the VPC, subnets, and RDS).
- `kubectl` installed locally.
- EKS is opt-in and **costly** - only run it while you are actively learning.

### Enable EKS

In `terraform/environments/dev/terraform.tfvars`:

```hcl
enable_eks = true
```

```bash
cd terraform
terraform plan -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan
terraform apply plan.tfplan
```

Expected output includes `eks_cluster_name`, `eks_cluster_endpoint`, and
`eks_connect_command`.

### Grant CI/CD kubectl access (one-time)

If `eks_ci_iam_arn` was left empty, add an access entry for the CI user:

```bash
aws eks create-access-entry \
  --cluster-name secure-ntier-dev-eks \
  --principal-arn arn:aws:iam::<ACCOUNT>:user/github-actions-cicd \
  --type STANDARD

aws eks associate-access-policy \
  --cluster-name secure-ntier-dev-eks \
  --principal-arn arn:aws:iam::<ACCOUNT>:user/github-actions-cicd \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

### Deploy the application to EKS

```bash
bash kubernetes/scripts/deploy.sh <git-sha> ap-south-1 dev secure-ntier
```

The script configures `kubectl`, materializes the DB credentials into the
`app-db-secret` Kubernetes Secret (from AWS Secrets Manager), **renders the
per-service Deployment/Service/HPA/PDB manifests from `stack.json`**
(`kubernetes/scripts/render-manifests.sh`), applies everything, points the
deployments at the ECR images, and waits for the rollouts.

### Verification

- `kubectl get all -n secure-ntier` → deployments/services/HPA present
- `kubectl -n secure-ntier get svc frontend` → NLB hostname assigned
- `curl -s http://<NLB>/health` → `db: "connected"`
- `kubectl -n secure-ntier get hpa` → replicas scale as CPU rises
- HPA + PDB exist → `kubectl -n secure-ntier get hpa,pdb`

### Optional: wire the pipelines

- GitHub Actions: set repo variable `DEPLOY_EKS=true` → `deploy-eks` job runs
  on every push to `main`.
- Jenkins: tick `DEPLOY_EKS` on the job (needs `kubectl` on the agent).
- Jenkins CI: `cicd/Jenkinsfile-ci` gates PRs/develop (same as `ci.yml`).

### Common errors

- **`context was not found`** — run `aws eks update-kubeconfig` for the right
  cluster/region.
- **`AccessDenied` on `update-kubeconfig`** — the CI principal needs the EKS
  access entry (step above) + `eks:DescribeCluster`.
- **Backend unhealthy / `ECONNREFUSED` to RDS** — the DB security group must
  include the EKS cluster security group (the root module does this
  automatically when `enable_eks = true`).
- **NLB never gets a hostname** — check `kubectl describe svc frontend -n
  secure-ntier` for quota / subnet errors.

### Next phase

Phase 31 — Cleanup.

---

## Phase 31 — Cleanup

### Objective

Shut everything down to stop billing — and prove `terraform destroy` is safe
and repeatable.

### Why we need it

Cost safety is part of the design: a NAT Gateway + RDS + ALB + 2×EC2 billing
happens every day until you stop it.

### Commands

```bash
cd terraform
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

### Expected output

`Destroy complete! Resources: 0 remaining.` — everything Terraform created is
gone.

### Manual cleanup (resources Terraform can't fully remove)

| Resource | Action |
| -------- | ------ |
| S3 buckets (`-cloudtrail`, `-alb-logs`, state bucket) | empty + delete, or keep state bucket versioned |
| Route 53 hosted zone | delete via console if no longer needed |
| CloudWatch Log Groups (flow logs, app logs) | delete to stop storage cost |
| Secrets Manager (destroyed secret versions) | verify none remain; rotate leftovers |
| GitHub secrets | remove if the repo is archived |

```bash
# helper
bash scripts/cleanup.sh ap-south-1 secure-ntier dev
```

### Verification

- Billing-free: check the AWS Cost Explorer / billing for the following days.
- No resources remain: `aws ec2 describe-instances --filters Name=instance-state-name,Values=running`.

### Common errors

- **Destroy hangs on RDS** — `deletion_protection=true` blocks it by design;
  set `deletion_protection=false` (or delete the DB manually) after removing
  protection.
- **Non-empty S3 buckets block destroy** — `force_destroy = true` is set on
  project buckets; the **state bucket** is intentionally preserved — delete it
  manually on purpose, not by accident.

### Security notes

- After teardown, invalidate IAM access keys that are no longer needed.

### Beginner explanation

- **terraform destroy** = reverse of apply: tear down every resource in `tfstate`
  in dependency-safe order.

### Interview questions

- *"Which resources will remain after terraform destroy?"* — anything created
  outside Terraform (state bucket, DynamoDB lock table, Route 53 zone if manual,
  CloudWatch log groups) and anything protected (deletion-protected RDS).

### Phase completion checklist

- [ ] `terraform destroy` completes
- [ ] Manual cleanup items handled
- [ ] No running instances / no billable resources remain

---

## Recap — what you built

```text
Secure, automated, n-tier platform on AWS
├── Network   VPC 10.0.0.0/16, 6 subnets ×3 tiers, IGW, NAT, NACLs, flow logs
├── Compute   2× EC2 (Ubuntu) in ASG (min2/max4), Docker via user-data
├── LB        ALB with TLS + WAF managed rules
├── Data      RDS PostgreSQL (encrypted, private) + Secrets Manager
├── CDN/DNS   Route 53 + ACM (HTTPS)
├── CI/CD     GitHub Actions: test → scan → ECR → SSM → instance refresh
├── Observability CloudWatch alarms → SNS; CloudTrail; flow logs; dashboard
└── Operations 30-phase guide, runbooks, ADRs, DR plan, cost guide
```

Move on to [`testing.md`](./testing.md), [`cost-guide.md`](./cost-guide.md),
and [`interview-questions.md`](./interview-questions.md) next.