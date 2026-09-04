# Terraform Infrastructure Screenshots

This folder contains verification screenshots demonstrating automated infrastructure provisioning using HashiCorp Terraform on AWS (`ap-south-1`).

---

## 📋 Recommended Captures

| Filename | Description | Context |
|---|---|---|
| `01-terraform-init-backend.png` | Successful remote state initialization (`S3 + DynamoDB`) | [`docs/deployment/terraform.md`](../../docs/deployment/terraform.md) |
| `02-terraform-fmt-validate.png` | Code formatting check and syntax validation output | Validation Gate |
| `03-terraform-plan.png` | Plan execution summary detailing resources to be created | Pre-deployment Check |
| `04-terraform-apply-output.png` | Successful apply completion and provisioned resource counts | Infrastructure Provisioning |
| `05-terraform-outputs.png` | Output manifest showing ALB DNS name and RDS endpoints | Service Hand-off |
| `06-terraform-destroy.png` | Infrastructure teardown confirmation | Cleanup & Teardown |
| `07-backend-s3-lock.png` | AWS S3 state bucket with Versioning & SSE-KMS enabled | State Security |
| `08-multi-cloud-dispatch.png` | Multi-cloud dispatch validation (`-var="cloud=aws"`) | Multi-Cloud Architecture |

All screenshots should be placed in this folder as PNG files (`< 600 KB`).
