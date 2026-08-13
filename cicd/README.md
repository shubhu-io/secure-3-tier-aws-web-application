# CI/CD

This project can run on **two compatible pipeline engines**, both feeding the
same shared shell scripts in `cicd/scripts/`:

| Engine | Entry | Best for |
| ------ | ----- | -------- |
| **GitHub Actions** | `.github/workflows/*.yml` | GitHub-hosted, zero infrastructure |
| **Jenkins** | `cicd/Jenkinsfile` + `cicd/jenkins/README.md` | self-hosted / existing Jenkins |

> Pick one as your source of truth and keep it green — running both on `main`
> triggers competing deploys to the same SSM deploy pointer (last writer wins).
> The Jenkins setup guide is at `jenkins/README.md`.

## Workflows

| File | Trigger | What it does |
| ---- | ------- | ------------ |
| `.github/workflows/ci.yml` | PR to `main`/`develop`, push to `develop` | Backend tests + `npm audit`, frontend build, Docker build + Trivy scan, Terraform fmt/validate |
| `.github/workflows/ci.yml` (`ensure-stable` / `head` corner-cases) | — | Docker build-arg pinning and scan checks on PRs |
| `.github/workflows/deploy.yml` | push to `main` | Tests → ECR login → build+push both images → Trivy → update SSM params → rolling instance refresh → smoke test |
| `.github/workflows/terraform.yml` | PR / push to `main` / manual dispatch | Terraform fmt+validate+plan on PRs, plan+apply **dev** on merge, plan+apply **prod** via `workflow_dispatch` with `auto_apply=true` |

### The Terraform workflow in detail

```text
PR → plan dev + comment on the PR (with destroy preview)
    └─ (also runs a no-AWS validate-only job for fast feedback)

merge to main → plan + apply dev (cheap, safe)

manual dispatch (prod) → plan prod → apply prod (only if auto_apply=true)
```

Terraform remote state (`environments/{dev,prod}/backend.hcl`) can be
bootstraped with `terraform/scripts/bootstrap-state.sh` before first use.

## Scripts

| Script | Purpose |
| ------ | ------- |
| `ecr-login.sh <region>` | Authenticate Docker to ECR |
| `build-and-push.sh <repo> <tag> <region> [project] [env]` | Build + push one image (tagged with git SHA + `latest`) |
| `deploy-ec2.sh <tag> <region> [env] [project]` | Point the SSM image params at the new image and start an ASG instance refresh |
| `smoke-test.sh` | Poll `/health` until the app returns 200 with db connected |

## How a deploy works (the important part)

The EC2 instances never pull "whatever is tagged latest" — that would be
unreproducible. Instead:

```text
git push → pipeline builds image :<git-sha>
        → pushes to ECR
        → writes <sha>-tagged URI into SSM Parameter Store
        → starts a rolling ASG instance refresh
        → new instances boot, read the URI from SSM, pull that exact image
```

Every deployed instance runs the exact image that passed tests and scans, and
the git SHA is traceable end to end.

## Running the same deploy manually

```bash
bash scripts/deploy.sh <tag> <region> <project> <env>
```
