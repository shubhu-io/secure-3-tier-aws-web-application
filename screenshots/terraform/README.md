# Terraform Step Screenshots — Image Ideas

Place images here: `screenshots/terraform/*.png`

## Ideas — generate these terminals (see `../IMAGE_IDEAS.md` for full spec)

1. `01-terraform-init-backend.png` — `terraform init -backend-config="cloud/aws/backend.hcl"` success
2. `02-terraform-fmt-validate.png` — `fmt -check` + `validate`
3. `03-terraform-plan.png` — plan showing resources to add
4. `04-terraform-apply-output.png` — apply complete + `app_url`
5. `05-terraform-outputs.png` — `terraform output`
6. `06-terraform-destroy.png` — destroy confirmation
7. `07-backend-s3-lock.png` — S3 + DynamoDB console
8. `08-multi-cloud-dispatch.png` — azure/gcp var dispatch (optional)

Usage in docs: `![Screenshot: terraform init](../../screenshots/terraform/01-terraform-init-backend.png)` in `docs/deployment/terraform.md`

You generate → I place & link where needed.
