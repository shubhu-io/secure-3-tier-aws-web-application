# GCP Implementation — Secure N-Tier Cloud Platform

This directory is the **GCP** implementation of the secure n-tier web platform
(React + Node/Express + PostgreSQL). It mirrors the structure and quality of
the AWS module at `../aws/` and is selected by the root dispatcher
(`terraform/main.tf`) via:

```hcl
module "gcp" {
  source = "./cloud/gcp"
  count  = var.cloud == "gcp" ? 1 : 0
  # ... every variable passed by the dispatcher ...
}
```

It is a **self-contained root module**: it owns its own `provider "google"`
block and reads `../stack.json` (the repo-root manifest) via `path.root`,
exactly like the AWS module.

## Architecture (GCP-native, secure by default)

```
                  ┌─────────────────────────────────────────────┐
   Internet ──────▶│ Global External HTTP(S) LB (static IP)     │
                  │   + Cloud Armor WAF (SQLi/XSS)              │
                  └───────────────┬─────────────────────────────┘
                                  │ (health checks from 130.211/16, 35.191/16)
                                  ▼
                  ┌─────────────────────────────────────────────┐
                  │ MIG (e2-small, no external IP) in app subnet │
                  │   • Docker pulled from Artifact Registry      │
                  │     via the VM SERVICE ACCOUNT (no creds)     │
                  │   • Cloud SQL Auth Proxy → 127.0.0.1:5432     │
                  └───────────────┬─────────────────────────────┘
                                  │ (5432, restricted to app subnet / GKE tag)
                                  ▼
                  ┌─────────────────────────────────────────────┐
                  │ Cloud SQL PostgreSQL — PRIVATE IP ONLY       │
                  │   credentials in Secret Manager (no code)    │
                  └─────────────────────────────────────────────┘
```

Outbound internet for the private instances is provided by **Cloud NAT**
(reserved IPs, count = `nat_gateway_count`). There are no public instance
IPs; administrative access uses **IAP browser-based SSH** (firewall allows
`35.235.240.0/20` only).

## Module layout

| Module        | GCP resources                                                                 | AWS analogue            |
|---------------|-------------------------------------------------------------------------------|-------------------------|
| `vpc`         | `google_compute_network` (custom mode) + 3 `google_compute_subnetwork` + `google_compute_router`/`router_nat` + reserved NAT IPs | `vpc`        |
| `security`    | `google_compute_firewall` rules: LB→app, app→db, gke→db, IAP-SSH, internal, egress | `security`   |
| `registry`    | `google_artifact_registry_repository` per service                             | `ecr`                   |
| `alb`         | `google_compute_global_forwarding_rule` + `target_https/http_proxy` + `url_map` + `backend_service` + `health_check` + static IP + `google_compute_security_policy` (Cloud Armor) | `alb` + WAF |
| `compute`     | `google_compute_instance_template` + `region_instance_group_manager` + `region_autoscaler` (CPU 70%) + service account + IAM | `compute`    |
| `database`    | `google_sql_database_instance` (private IP) + `google_sql_database` + `google_sql_user` + `google_secret_manager_secret` + private service connection | `database`   |
| `monitoring`  | `google_monitoring_notification_channel` (email) + `alert_policy` (CPU, 5xx) + `dashboard` | `monitoring` |
| `gke`*        | `google_container_cluster` (private) + `google_container_node_pool`          | `eks`                   |
| `jenkins`*    | `google_compute_instance` (Debian + Jenkins) + firewall + service account    | `jenkins`               |

\* `gke` and `jenkins` are instantiated with `count = var.enable_gke` /
`count = var.enable_jenkins`.

## Required outputs (consumed by the root dispatcher)

`app_url`, `lb_dns_name` (LB IP), `db_host` (sensitive, Cloud SQL private IP),
`db_secret_ref` (Secret Manager id), `registry_url`, `image_repository_urls`
(map), `asg_name` (MIG name), `topic_arn` (notification channel id),
`dashboard_name`, `web_acl_arn` (Cloud Armor policy id), `kubeconfig_command`
+ `cluster_endpoint` (GKE, empty when disabled), and `cicd_policy_json` — a
`jsonencode`'d list of the GCP IAM roles the CI/CD principal needs
(`roles/artifactregistry.writer`, `roles/compute.admin`,
`roles/cloudsql.admin`, `roles/monitoring.admin`,
`roles/secretmanager.secretAccessor`).

## Security posture

- **Private Cloud SQL** — no public IP; access only via the VPC private
  service connection and the Cloud SQL Auth Proxy (token-based, uses the VM
  service account). Firewall restricts 5432 to the app subnet (and the GKE
  node tag when GKE is enabled).
- **No embedded credentials** — compute instances pull images from Artifact
  Registry using a short-lived OAuth token fetched from the metadata server;
  DB secrets are read from Secret Manager at boot (VM SA has
  `secretmanager.secretAccessor`).
- **Cloud Armor WAF** — preconfigured SQLi/XSS rule sets in front of the LB.
- **Least-privilege service accounts** — the compute runtime SA gets only
  artifactregistry.reader / secretmanager.secretAccessor / logging /
  monitoring / cloudsql.client.

## Deviations / notes (interface parity only)

These root variables are declared for interface parity but have **no direct
GCP equivalent**; they are intentionally unused in logic:

- `alb_deletion_protection` — GCP LBs have no deletion-protection toggle.
- `enable_alb_access_logs` — GCP exports LB logs via Cloud Logging (not wired).
- `skip_final_snapshot` — Cloud SQL has no final-snapshot concept.
- `azs` — GCP uses zones derived from `region` (`<region>-a`, `<region>-b`).
- `nat_gateway_count` — mapped to the number of reserved Cloud NAT IPs (1 or 2).
- `db_multi_az` — mapped to Cloud SQL `availability_type = "REGIONAL"`.

## Usage

```bash
cd terraform
terraform init -backend-config="cloud/gcp/backend.hcl"
terraform plan  -var="cloud=gcp" -var="gcp_project=my-project" -var="gcp_region=europe-west1"
terraform apply -var="cloud=gcp" -var="gcp_project=my-project"
```

Enable the optional Kubernetes/Jenkins tiers with `-var="gcp_enable_gke=true"`
and `-var="gcp_enable_jenkins=true"`.
