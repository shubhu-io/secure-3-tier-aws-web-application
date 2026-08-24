# GCP Project Preparation

> ⚠️ **COST WARNING** — Everything on this page is free or near-free, but the
> **deployment** itself creates billable resources (MIG, external HTTPS load
> balancer, Cloud NAT, Cloud SQL, Artifact Registry, Cloud Monitoring). Read
> [`docs/cost-guide.md`](../cost-guide.md) before you `terraform apply`, and
> run `terraform destroy` when done.

> **Honesty note:** the GCP module (`terraform/cloud/gcp/`) is a port of the
> AWS reference implementation and is **pending live validation** — expect
> rough edges, and check GCP pricing for your region first.

## 1. Install the CLI and sign in

```bash
gcloud auth login
gcloud projects list
gcloud config set project <YOUR-PROJECT-ID>
gcloud config set compute/region europe-west1
```

Verify:

```bash
gcloud config list
```

## 2. Enable the required APIs (one-time)

```bash
gcloud services enable compute.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com
```

(Add `container.googleapis.com` when provisioning GKE with `gcp_enable_gke`.)

## 3. Prepare the Terraform state backend

By default each cloud's `backend.hcl` keeps state in an **S3 bucket** (a
cloud-agnostic choice shared across clouds — see
[`terraform/cloud/gcp/backend.hcl`](../../terraform/cloud/gcp/backend.hcl)).
If you prefer native GCS state, swap the backend block to `gcs` and create:

```bash
gsutil mb -p <YOUR-PROJECT-ID> -l EUROPE-WEST1 gs://<UNIQUE-STATE-BUCKET>
gsutil versioning set on gs://<UNIQUE-STATE-BUCKET>
```

Then initialize with `-backend-config="cloud/gcp/backend.hcl"` as documented
in [`terraform.md`](./terraform.md).

## 4. Create the CI/CD service account

GitHub Actions (or Jenkins) needs a non-interactive identity:

```bash
gcloud iam service-accounts create github-actions-cicd \
  --display-name "github-actions-cicd"
```

**Least privilege:** do not blanket-grant broad roles (`roles/editor`). After
the first `terraform apply`, bind exactly the permissions listed in Terraform's
normalized **`cicd_policy_json` output** (Artifact Registry push, MIG update,
etc.) — that document is the source of truth for what CI actually needs.
Before the first apply you will need enough to run Terraform itself (e.g.
`roles/compute.admin`, `roles/cloudsql.admin`, `roles/iam.roleAdmin` on this
learning project).

For GitHub Actions, prefer **Workload Identity Federation** over downloading a
JSON key:

```bash
gcloud iam workload-identity-pools create github-pool --location global
gcloud iam workload-identity-pools providers create-oidc github-oidc \
  --location global --workload-identity-pool github-pool \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository"
```

Then allow `repo:your-org/secure-ntier-cloud-platform` to impersonate the
service account and configure the `GCP_WORKLOAD_IDENTITY_PROVIDER` /
`GCP_SERVICE_ACCOUNT` repository secrets. If you must use a key instead,
create it (`gcloud iam service-accounts keys create`) and store it as the
`GOOGLE_APPLICATION_CREDENTIALS` secret — keys never live in Git.

If you provision GKE (`gcp_enable_gke = true`), grant the same service account
`roles/container.developer` so CI can fetch cluster credentials and deploy.

## 5. (Optional) Domain for HTTPS

The global HTTPS load balancer terminates TLS. Point your domain's DNS record
at the forwarding-rule IP (the Terraform output `lb_dns_name` / `app_url`)
once deployed.

## Next step

[Deploy infrastructure with Terraform](./terraform.md).
