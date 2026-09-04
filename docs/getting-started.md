# Getting Started — From Zero to Deployed

Everything you need to go from a fresh machine to a running secure n-tier platform
on AWS, Azure, or GCP. Follow the steps in order; each step builds on the one before.

## 0. Accounts & Access

| What | Why | How |
| ---- | --- | --- |
| **GitHub account** | Source code + CI/CD | <https://github.com/join> |
| **Cloud account** (choose one: AWS / Azure / GCP) | Infrastructure provisioning | <https://aws.amazon.com/free> · <https://azure.microsoft.com/free> · <https://cloud.google.com/free> |
| **Least-privilege credentials** | Secure access to cloud APIs | Create a dedicated IAM user / service principal (never root). Store results with `aws configure` / `az login` / `gcloud auth login`. Per-cloud setup: [AWS](./docs/deployment/aws-setup.md) · [Azure](./docs/deployment/azure-setup.md) · [GCP](./docs/deployment/gcp-setup.md). |

## 1. Install Required Tools

| Tool | Minimum | Why | Install |
| ---- | ------- | --- | ------- |
| **Git** | 2.x | Version control | <https://git-scm.com> |
| **Terraform** | ≥ 1.5 | Infrastructure as Code | <https://developer.hashicorp.com/terraform/install> |
| **Docker** | 20+ + Compose v2 | Local app stack + image builds | <https://docs.docker.com/engine/install/> |
| **Node.js** | 20+ | Build / run the app locally | <https://nodejs.org> |
| **AWS CLI v2** | 2.x | AWS API access (if targeting AWS) | <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html> |
| **Azure CLI** | 2.x | Azure API access (if targeting Azure) | <https://learn.microsoft.com/cli/azure/install-azure-cli> |
| **Google Cloud SDK** | — | GCP API access (if targeting GCP) | <https://cloud.google.com/sdk/docs/install> |
| **jq** | — | Parse JSON in scripts | Package manager (`apt`, `brew`, `choco`) |
| **mermaid-cli** (optional) | — | Render mermaid diagrams | `npm i -g mermaid.cli` or use <https://mermaid.live> |

### Verify your install

```bash
git --version
terraform version
docker --version && docker compose version
node --version   # >= 20
# plus the CLI for YOUR target cloud (only one needed):
aws --version
az --version
gcloud --version
```

If any check fails, see the [Prerequisites doc](./docs/deployment/prerequisites.md) for troubleshooting.

## 2. Clone the Repository

```bash
git clone https://github.com/shubhu-io/secure-3-tier-aws-web-application.git
cd secure-3-tier-aws-web-application
```

> Or with SSH: `git clone git@github.com:shubhu-io/secure-3-tier-aws-web-application.git`

Skim [`stack.json`](./stack.json) first — it is the single source of truth that drives CI/CD, Terraform, and Kubernetes rendering.

## 3. Run the Application Locally (Free, No Cloud Account)

Start the app stack using Docker Compose — no cloud credentials needed.

```bash
cd docker
docker compose up --build
```

In a second terminal:

```bash
curl http://localhost/health    # expect {"status":"ok","db":"connected"}
```

UI: http://localhost · API: http://localhost/api/items

Stop it with `Ctrl+C`, then `docker compose down` (add `-v` to wipe the DB).

## 4. Authenticate to Your Chosen Cloud

```bash
# AWS
aws configure                    # enter access key, secret key, region, output format
az login                         # Azure (opens browser)
gcloud auth login                # GCP (opens browser)
gcloud config set project <PROJECT_ID>   # set your GCP project
```

Per-cloud least-privilege setup:

- [AWS](./docs/deployment/aws-setup.md)
- [Azure](./docs/deployment/azure-setup.md)
- [GCP](./docs/deployment/gcp-setup.md)

## 5. Configure the Deployment

```bash
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
```

Edit at minimum `notification_email`; tune region/sizes per the [Configuration table](./README.md#-configuration) (AWS/Azure/GCP variants included).

## 6. Provision Infrastructure (Terraform)

All three clouds share the same Terraform root module — only the selected cloud
is instantiated (the other two are disabled via `count = 0`).

### 6a. Initialize the Remote State Backend (One-Time)

Terraform state is stored in S3 with DynamoDB locking (cloud-agnostic backend
used for all three providers). Create it once:

```bash
bash terraform/scripts/bootstrap-state.sh <region> [bucket-name]
```

Examples:

```bash
bash terraform/scripts/bootstrap-state.sh ap-south-1
bash terraform/scripts/bootstrap-state.sh ap-south-1 my-org-terraform-state
```

Then the environments already point at this bucket (see
`terraform/cloud/*/backend.hcl`).

### 6b. Initialize & Plan

```bash
cd terraform

# AWS
terraform init -backend-config="cloud/aws/backend.hcl"
terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan

# Azure
terraform init -backend-config="cloud/azure/backend.hcl"
terraform plan -var="cloud=azure" -var="azure_location=westeurope" -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan

# GCP
terraform init -backend-config="cloud/gcp/backend.hcl"
terraform plan -var="cloud=gcp" -var="gcp_project=my-project" -var="gcp_region=europe-west1" -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan
```

### 6c. Apply

```bash
terraform apply plan.tfplan     # ~10-15 minutes; prints app_url at the end
```

## 7. Verify the Deployment

After `terraform apply` finishes, you’ll see an `app_url` output. Verify it:

```bash
curl "$app_url/health"    # expect {"status":"ok","db":"connected"}
```

Or run the check script:

```bash
bash scripts/health-check.sh
```

## 8. Set Up CI/CD

### 8a. GitHub Actions (recommended)

1. Push this repo to your GitHub account.
2. Add repository secrets (Settings → Secrets → Actions):

| Secret | Needed for |
| -------- | ---------- |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | AWS deploy |
| `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_CLIENT_SECRET` | Azure deploy |
| `GCP_SA_KEY` / `GCP_PROJECT_ID` | GCP deploy |

3. The `.github/workflows/deploy.yml` pipeline is driven by `stack.json` and the
   `CLOUD` variable (defaults to `aws`, can be overridden on manual dispatch).

### 8b. Self-Hosted Jenkins (optional alternative)

See [`docs/deployment/jenkins.md`](./docs/deployment/jenkins.md) for prerequisites,
credential setup, and pipeline job creation.

## 9. Optional: Kubernetes / EKS / AKS / GKE

The platform already provisions the Kubernetes cluster via Terraform (EKS, AKS,
or GKE depending on your cloud choice). To deploy updated images:

```bash
# Example: update image tag in the manifests, then:
aws eks update-kubeconfig --region ap-south-1 --name <cluster-name>
kubectl apply -k k8s/overlays/prod
```

## 10. Tear Down When Done

```bash
cd terraform
terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
```

Then follow the [Cleanup checklist](./README.md#-cleanup) so nothing keeps billing.

## 11. Multi-Cloud Note

The root `terraform/main.tf` dispatches to exactly **one** cloud based on the
`var.cloud` variable. When `cloud = aws` only the AWS module is instantiated
(count = 1); Azure and GCP modules have count = 0 and zero resources in state.
Same logic applies for `azure` and `gcp`. This means:

- At plan time you only need credentials for the selected cloud.
- `stack.json` drives CI/CD, so the same repo can deploy to any cloud by
  changing the `CLOUD` variable.
- Remote state backend is shared (S3 + DynamoDB) even when targeting Azure or
  GCP — the backend is cloud-agnostic.

---

**Next steps:** Read the deep-dive guides in order:

| Step | Guide |
| ---- | ----- |
| 1. Understand the phases | [`docs/phases.md`](../phases.md) |
| 2. Prepare your machine | [`docs/deployment/prerequisites.md`](../deployment/prerequisites.md) |
| 3. Prepare your cloud | [AWS](./docs/deployment/aws-setup.md) · [Azure](./docs/deployment/azure-setup.md) · [GCP](./docs/deployment/gcp-setup.md) |
| 4. Deploy infrastructure | [`docs/deployment/terraform.md`](../deployment/terraform.md) |
| 5. Run the app locally first | [`docs/deployment/application.md`](../deployment/application.md) |
| 6. Set up CI/CD | [`docs/deployment/cicd.md`](../deployment/cicd.md) |
| 7. (Optional) Kubernetes / EKS | [`docs/deployment/eks.md`](../deployment/eks.md) |
| 8. (Optional) Self-hosted Jenkins | [`docs/deployment/jenkins.md`](../deployment/jenkins.md) |

---
*This guide is intentionally beginner-friendly and covers every basic step from
starting from scratch. For deeper dives (costs, ADRs, monitoring, troubleshooting),
see the documentation index in the [README](../README.md).*