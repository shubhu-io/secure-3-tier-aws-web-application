# Deployment Verification & Screenshot Catalog

This document provides the canonical specification and naming reference for all **visual deployment verification artifacts** across the platform lifecycle.

All captures should be saved as high-clarity PNG files under their corresponding subdirectories within `screenshots/`.

---

## 🗺️ Verification Domains

| Directory | Target Domain | Core Focus |
|---|---|---|
| [`terraform/`](./terraform/) | Infrastructure as Code | Multi-AZ VPC, ASG, RDS, and IAM provisioning verification |
| [`jenkins/`](./jenkins/) | Enterprise CI/CD Controller | Pipeline stage view, automated Trivy scans, and ASG rolling updates |
| [`cicd/`](./cicd/) | GitHub Actions Automation | Automated pull request validation, Docker container build & push |
| [`deployment/`](./deployment/) | Application & Ingress | ALB endpoint verification, health JSON probes, and UI authentication |
| [`monitoring/`](./monitoring/) | Observability & Reliability | CloudWatch dashboards, metric alarms, and SNS alert subscriptions |
| [`kubernetes/`](./kubernetes/) | Container Orchestration (Optional) | Amazon EKS nodes, pods, and AWS Load Balancer Controller |

---

## 1. Terraform Infrastructure Verification (`screenshots/terraform/`)

| ID | Recommended Filename | Description / Terminal Output | Target Document |
|---|---|---|---|
| **T01** | `01-terraform-init-backend.png` | `terraform init` with remote S3 state and DynamoDB lock table | [`docs/deployment/terraform.md`](../docs/deployment/terraform.md) |
| **T02** | `02-terraform-fmt-validate.png` | Clean output of `terraform fmt -check` and `terraform validate` | [`docs/deployment/terraform.md`](../docs/deployment/terraform.md) |
| **T03** | `03-terraform-plan.png` | `terraform plan` execution previewing resource additions | [`docs/deployment/terraform.md`](../docs/deployment/terraform.md) |
| **T04** | `04-terraform-apply-output.png` | Successful apply showing `Apply complete! Resources: 28 added` | [`docs/deployment/terraform.md`](../docs/deployment/terraform.md) |
| **T05** | `05-terraform-outputs.png` | `terraform output` displaying `alb_dns_name`, `rds_endpoint`, `ecr_url` | Verification Section |
| **T06** | `06-terraform-destroy.png` | `terraform destroy` confirmation and clean resource teardown | Teardown Guide |
| **T07** | `07-backend-s3-lock.png` | AWS Console view of S3 state bucket with Versioning Enabled | Remote State Guide |
| **T08** | `08-multi-cloud-dispatch.png` | Multi-cloud dispatch validation (`-var="cloud=aws"`) | Multi-Cloud Guide |

---

## 2. Jenkins Automation Verification (`screenshots/jenkins/`)

| ID | Recommended Filename | Description / Interface | Target Document |
|---|---|---|---|
| **J01** | `01-jenkins-provision.png` | Terraform completion output exposing automated Jenkins controller URL | [`docs/deployment/jenkins.md`](../docs/deployment/jenkins.md) |
| **J02** | `02-jenkins-unlock.png` | Initial Jenkins administrative unlock screen | Setup Walkthrough |
| **J03** | `03-jenkins-plugins.png` | Standard pipeline and AWS plugin installation progress | Setup Walkthrough |
| **J04** | `04-jenkins-credentials-aws.png` | Secure credential store with IAM role & GitHub access token | Credentials Guide |
| **J05** | `05-jenkins-agent-docker.png` | Dynamic Docker agent node active and connected | Node Configuration |
| **J06** | `06-jenkins-ci-pipeline.png` | `Jenkinsfile-ci` pipeline green stage view (Lint, Test, Trivy scan) | CI Pipeline Section |
| **J07** | `07-jenkins-deploy-pipeline.png` | `Jenkinsfile` deploy pipeline (Build, ECR Push, ASG Refresh) | Deployment Section |
| **J08** | `08-jenkins-build-log.png` | Console snippet demonstrating zero vulnerabilities in Trivy scan | Security Gates |
| **J09** | `09-jenkins-asg-refresh.png` | AWS Console showing zero-downtime ASG Instance Refresh activity | Operations Guide |

---

## 3. GitHub Actions CI/CD Verification (`screenshots/cicd/`)

| ID | Recommended Filename | Description / Interface | Target Document |
|---|---|---|---|
| **C01** | `01-actions-ci-green.png` | Pull Request automated status check with green CI validation | [`cicd/README.md`](../cicd/README.md) |
| **C02** | `02-actions-deploy-green.png` | Automated continuous deployment workflow completed on `main` branch | [`cicd/README.md`](../cicd/README.md) |
| **C03** | `03-actions-terraform-plan.png` | Automated PR comment summarizing Terraform plan execution | Pull Request Checks |
| **C04** | `04-ecr-images-pushed.png` | AWS ECR repository console displaying SHA-tagged Docker images | Container Registry |
| **C05** | `05-smoke-test-log.png` | Automated post-deploy smoke test verifying HTTP 200 on `/health` | Verification Section |

---

## 4. Live Application & Ingress Verification (`screenshots/deployment/`)

| ID | Recommended Filename | Description / Interface | Target Document |
|---|---|---|---|
| **D01** | `01-app-ui-login.png` | Live browser rendering of React authentication UI in `ap-south-1` | [`README.md`](../README.md) |
| **D02** | `02-app-health-json.png` | Terminal curl probe confirming `{ status: "ok", database: "connected" }` | [`README.md`](../README.md) |
| **D03** | `03-alb-targets-healthy.png` | AWS EC2 Target Group dashboard displaying 2× healthy targets | Verification Section |
| **D04** | `04-app-items-crud.png` | Web application items CRUD lifecycle verifying PostgreSQL writes | Feature Guide |
| **D05** | `05-rds-private.png` | AWS RDS console verifying Multi-AZ synchronous replication & private subnet | Database Guide |
| **D06** | `06-secrets-manager.png` | AWS Secrets Manager console showing automated credential storage | Security Section |
| **D07** | `07-waf-webacl.png` | AWS WAF v2 console showing attached Web ACL rules on ALB | Edge Security |
| **D08** | `08-sg-chain.png` | EC2 Security Group rules showing chained ingress restriction | Network Hardening |

---

## 5. Observability & Monitoring Verification (`screenshots/monitoring/`)

| ID | Recommended Filename | Description / Interface | Target Document |
|---|---|---|---|
| **M01** | `01-cloudwatch-dashboard.png` | CloudWatch unified dashboard with CPU, Memory, and ALB metrics | Monitoring Guide |
| **M02** | `02-cloudwatch-alarms.png` | Active CloudWatch alarm state table (CPU > 70%, 5xx errors) | Incident Runbooks |
| **M03** | `03-sns-subscription.png` | AWS SNS console displaying confirmed notification topic endpoints | Notification Setup |

---

## 6. Optional Kubernetes Cluster Verification (`screenshots/kubernetes/`)

| ID | Recommended Filename | Description / Interface | Target Document |
|---|---|---|---|
| **K01** | `01-eks-cluster.png` | AWS EKS console showing cluster in `ACTIVE` state | EKS Architecture |
| **K02** | `02-kubectl-get-pods.png` | `kubectl get pods -n secure-ntier` confirming all microservices running | K8s Operations |
| **K03** | `03-kubectl-get-svc.png` | `kubectl get svc` displaying ALB Ingress controller DNS binding | Ingress Routing |
| **K04** | `04-hpa-pdb.png` | `kubectl get hpa` confirming Horizontal Pod Autoscaler policies | Pod Scaling |

---

## 📜 Technical Standards

* **Aspect Ratio:** 16:9 widescreen captures preferred for dashboard and UI views.
* **Resolution:** 1920×1080 (1080p) or clean cropped terminal windows.
* **Theme:** Consistent dark or light themes matching modern developer toolchains.
* **Redaction:** Account numbers, private VPC IDs, and API authorization tokens must be masked before publication.
