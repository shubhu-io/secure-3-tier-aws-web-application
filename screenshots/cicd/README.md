# GitHub Actions CI/CD Screenshots

This folder contains verification screenshots documenting automated continuous integration and delivery workflows managed via GitHub Actions.

---

## 📋 Recommended Captures

| Filename | Description | Context |
|---|---|---|
| `01-actions-ci-green.png` | Pull Request automated checks passing (Lint, Test, Trivy CVE scan) | Pull Request Quality Gates |
| `02-actions-deploy-green.png` | Successful continuous deployment workflow on `main` branch | Automated Production Release |
| `03-actions-terraform-plan.png` | Automated pull request comment detailing Terraform plan output | Infrastructure Review |
| `04-ecr-images-pushed.png` | AWS ECR repository displaying immutable Git SHA tagged images | Container Registry |
| `05-smoke-test-log.png` | Post-deployment smoke test logs confirming HTTP 200 responses | Verification & Rollback |

Refer to [`cicd/README.md`](../../cicd/README.md) for workflow definitions.
