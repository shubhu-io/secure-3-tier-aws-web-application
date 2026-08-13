# GitHub Actions — CI/CD

This folder documents the GitHub Actions pipelines. The **actual workflow
files** live in `.github/workflows/`, not here — these are the design docs and
supporting references.

## Pipelines

| Workflow | File | Branch trigger | What it does |
| -------- | ---- | -------------- | ------------ |
| **CI** | `.github/workflows/ci.yml` | PR to `main`/`develop`; push to `develop` | backend tests + npm audit, frontend build, docker build, Trivy scan, terraform fmt/validate |
| **Deploy (CD)** | `.github/workflows/deploy.yml` | push to `main` | tests → ECR auth → build+push images → Trivy gate → update SSM params → ASG instance refresh → smoke test |

## CI stages (safety net before main)

```text
Checkout → Node 20 → npm ci → npm test → npm audit (high gate)
Frontend: check build
Docker: build backend + frontend → Trivy (CRITICAL/HIGH → fail)
Terraform: fmt check + validate (+ plan-check in tests/)
```

Purpose: **catch broken code before it reaches main.** Nothing here touches AWS.

## Deploy stages (the release path)

```text
Checkout → AWS creds (GitHub secrets) → npm test + audit
→ ecr-login → build+push backend:X → build+push frontend:X
→ Trivy gate on both images
→ deploy-ec2 (SSM pointer update + instance refresh)
→ smoke-test against ALB
```

Purpose: turn `main` into a live, verified release. A failing scan or smoke
test leaves the previous version serving traffic (rollback = re-point SSM).

## Supporting scripts

| Script | Purpose |
| ------ | ------- |
| `scripts/ecr-login.sh` | `aws ecr get-login-password` → docker login |
| `scripts/build-and-push.sh` | build `app:${sha}`, tag, push, echo URI |
| `scripts/deploy-ec2.sh` | write SSM image params + start instance refresh |
| `scripts/smoke-test.sh` | poll `$ALB_URL/health` until 200 or timeout |

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

## IAM needed by the pipeline

Least-privilege policy in `security/iam/cicd-policy.json` and provisioned as an
IAM policy by Terraform (`terraform/main.tf` → `cicd_policy_arn` output).
Actions: ECR auth/push, SSM put/update image params, ASG instance refresh,
target health + cloudwatch reads.

## Production upgrade

Replace long-lived keys with **OIDC federation** (a `AssumeRoleWebIdentity` role
trusting `token.actions.githubusercontent.com`) so no credentials are stored in
GitHub at all.