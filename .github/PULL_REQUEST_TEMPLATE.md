> **Before opening a pull request**, check the box(es) that apply.

## Type of change

- [ ] feat: new capability
- [ ] fix: bug fix
- [ ] security: security hardening
- [ ] refactor: no behavior change
- [ ] docs: documentation only
- [ ] test: tests only

## Description

<!-- What and why. Reference any issue: Fixes #NN -->

## How was this tested?

<!-- Be specific. Run the commands and paste results. -->

- [ ] `npm test` (application/backend)
- [ ] `npm run build` (application/frontend)
- [ ] `terraform fmt -check -recursive && terraform validate` (terraform/)
- [ ] `bash tests/infrastructure/terraform-validate.sh`
- [ ] `bash tests/infrastructure/tfplan-check.sh` (if infra changed)
- [ ] `bash tests/security/security-tests.sh` (if security/infra changed)
- [ ] Docker build + `trivy image --exit-code 1 --severity CRITICAL,HIGH`

## Checklist

- [ ] No secrets committed (`.env`, `*.tfvars`, `*.tfstate*`, `*.pem`, keys are ignored)
- [ ] No `node_modules`, build output, or state committed
- [ ] Docs updated (`diagrams/*.mmd` kept in sync with Terraform resources)
- [ ] CHANGELOG entry added for user-visible changes
- [ ] If a resource name / variable / output changed → every reference updated

## Labels for maintainers

- (leave to maintainers) default to `Terraform` / `Docker` / `App` / `CI-CD` / `Security` as applicable