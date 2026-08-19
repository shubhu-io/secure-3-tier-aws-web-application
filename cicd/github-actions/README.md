# GitHub Actions — CI/CD

This folder documents the GitHub Actions pipelines. The **actual workflow
files** live in `.github/workflows/`, not here — these are the design docs and
supporting references.

## Pipelines

The pipelines are **manifest-driven**: every stage loops over `stack.json`, so a
new service needs only a `stack.json` entry (no workflow edits).

| Workflow | File | Branch trigger | What it does |
| -------- | ---- | -------------- | ------------ |
| **CI** | `.github/workflows/ci.yml` | PR to `main`/`develop`; push to `develop` | `stack-validate` → per-service `stack-ci` (ci_steps in toolchain container + docker build + Trivy scan) → terraform fmt/validate |
| **Deploy (CD)** | `.github/workflows/deploy.yml` | push to `main` | `stack-validate` → `stack-ci` (tests + audit + scan gate) → `stack-push` (build + push every service to ECR) → `deploy-ec2` (per-service SSM params + ASG instance refresh) → smoke test → optional `deploy-eks` + NLB smoke test |

## CI stages (safety net before main)

```text
Checkout → stack-validate (manifest sanity)
→ stack-ci per service: ci_steps in toolchain container → npm test → npm audit (high gate)
→ docker build → Trivy (CRITICAL/HIGH → fail)
Terraform: fmt check + validate (+ plan-check in tests/)
```

Purpose: **catch broken code before it reaches main.** Nothing here touches AWS.

## Deploy stages (the release path)

```text
Checkout → AWS creds (GitHub secrets) → stack-validate
→ stack-ci per service (tests + audit + build + Trivy gate)
→ stack-push: build + push every service to ECR (:git-sha + :latest)
→ deploy-ec2 (per-service SSM pointer update + instance refresh)
→ smoke-test against ALB
→ [optional, if DEPLOY_EKS=true] deploy-eks (kubeconfig + render-manifests + secret + apply + roll)
   → smoke-test against the NLB endpoint
```

Purpose: turn `main` into a live, verified release. A failing scan or smoke
test leaves the previous version serving traffic (rollback = re-point SSM or
`kubectl rollout undo`).

## Supporting scripts

| Script | Purpose |
| ------ | ------- |
| `cicd/scripts/stack-validate.sh` | validate the `stack.json` manifest (schema, services, db) |
| `cicd/scripts/stack-info.sh` | print computed info (services, ports, repos) from `stack.json` |
| `cicd/scripts/stack-ci.sh` | CI per service: run its `ci_steps` in the toolchain container + docker build + trivy scan |
| `cicd/scripts/stack-push.sh` | build + tag + push every service image to ECR (`:sha` + `:latest`) |
| `cicd/scripts/ecr-login.sh` | `aws ecr get-login-password` → docker login |
| `cicd/scripts/build-and-push.sh` | build `app:${sha}`, tag, push, echo URI |
| `cicd/scripts/deploy-ec2.sh` | write SSM image params + start instance refresh |
| `cicd/scripts/deploy-eks.sh` | deploy to EKS + smoke test (wraps `kubernetes/scripts/deploy.sh`) |
| `cicd/scripts/smoke-test.sh` | poll `$ALB_URL/health` until 200 or timeout |

## GitHub repository secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret | Example | Used by |
| ------ | ------- | ------- |
| `AWS_ACCESS_KEY_ID` | `AKIA...` | deploy |
| `AWS_SECRET_ACCESS_KEY` | `...` | deploy |
| `AWS_REGION` | `eu-west-1` | deploy |
| `ALB_URL` | `http://secure-ntier-dev-alb-…elb.amazonaws.com` | smoke test |
| `ECR_PROJECT` | `secure-ntier` | image naming |
| `ECR_ENV` | `dev` | image naming |

Plus one **repository variable** (Settings → Variables → Actions):

| Variable | Example | Used by |
| -------- | ------- | ------- |
| `DEPLOY_EKS` | `true` | gate the optional `deploy-eks` job (only set when the Terraform EKS module was applied) |

## IAM needed by the pipeline

Least-privilege policy in `security/iam/cicd-policy.json` and provisioned as an
IAM policy by Terraform (`terraform/main.tf` → `cicd_policy_arn` output).
Actions: ECR auth/push, SSM put/update image params, ASG instance refresh,
target health + cloudwatch reads.

## Production upgrade

Replace long-lived keys with **OIDC federation** (a `AssumeRoleWebIdentity` role
trusting `token.actions.githubusercontent.com`) so no credentials are stored in
GitHub at all.