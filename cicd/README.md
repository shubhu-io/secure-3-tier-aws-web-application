# CI/CD

This project can run on **two compatible pipeline engines**, both feeding the
same shared shell scripts in `cicd/scripts/`:

| Engine | Entry | Best for |
| ------ | ----- | -------- |
| **GitHub Actions** | `.github/workflows/*.yml` | GitHub-hosted, zero infrastructure |
| **Jenkins** | `cicd/Jenkinsfile` + `cicd/Jenkinsfile-ci` + `cicd/jenkins/README.md` | self-hosted / existing Jenkins |

> Pick one as your source of truth and keep it green — running both on `main`
> triggers competing deploys to the same SSM deploy pointer (last writer wins).
> The Jenkins setup guide is at `jenkins/README.md` and
> `../docs/deployment/jenkins.md`.

## The `stack.json` manifest (single source of truth)

Every pipeline stage loops over **`stack.json`** instead of hardcoding services.
A service is a list of `{ name, language, port, public, source_dir, dockerfile,
toolchain, ci_steps, health_path }`; the database engine/version/port and the
supported runtimes live there too. Adding a service = one manifest entry:

- `stack-validate.sh` — schema-check the manifest (names, ports, dockerfiles exist, exactly one public service).
- `stack-ci.sh` — for each service: run `ci_steps` in its toolchain container → `docker build` → **Trivy** scan.
- `stack-push.sh` — for each service: `build-and-push.sh` to ECR (`:sha` + `:latest`).
- `deploy-ec2.sh` — for each service: update the SSM image pointer → one ASG instance refresh.
- `deploy-eks.sh` / `kubernetes/scripts/render-manifests.sh` — for each service: render + apply the k8s manifests.

The **Terraform** modules consume the same file (database engine/port, service
names for the SSM parameters and compose generation), so EC2 + EKS + CI/CD all
follow one source of truth.

## Workflows

| File | Trigger | What it does |
| ---- | ------- | ------------ |
| `.github/workflows/ci.yml` | PR to `main`/`develop`, push to `develop` | `stack-validate` → CI per service (tests + audit + Docker build + Trivy) via `stack-ci.sh` → Terraform fmt/validate |
| `.github/workflows/deploy.yml` | push to `main` | ECR login → build+push every service via `stack-push.sh` → update SSM params → rolling instance refresh → smoke test (+ optional EKS deploy when `DEPLOY_EKS=true`) |
| `.github/workflows/terraform.yml` | PR / push to `main` / manual dispatch | Terraform fmt+validate+plan on PRs, plan+apply **dev** on merge, plan+apply **prod** via `workflow_dispatch` with `auto_apply=true` |
| `cicd/Jenkinsfile` | push to `main` (Jenkins) | Same as `deploy.yml`: CI per service → ECR push → SSM → instance refresh → optional EKS → smoke test |
| `cicd/Jenkinsfile-ci` | PR / develop (Jenkins) | Same as `ci.yml`: manifest validate → CI per service → Terraform fmt/validate |

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
| `stack-validate.sh` | Validate the `stack.json` manifest (schema, paths, exactly one public service) |
| `stack-info.sh` | Read `stack.json` (project, services, fields, ci_steps, db engine/version/port) |
| `stack-ci.sh [project]` | CI for every service: ci_steps in toolchain container → docker build → Trivy scan (no AWS) |
| `stack-push.sh <tag> <region> [project] [env]` | Build + push **every** service to ECR (`:sha` + `:latest`) |
| `ecr-login.sh <region>` | Authenticate Docker to ECR |
| `build-and-push.sh <svc> <tag> <region> [project] [env] [dockerfile]` | Build + push one image |
| `deploy-ec2.sh <tag> <region> [env] [project]` | Point the SSM image params at the new image and start an ASG instance refresh |
| `deploy-eks.sh <tag> <region> [env] [project] [cluster]` | Deploy to EKS (kubeconfig, secret materialization, apply, roll, smoke test) |
| `smoke-test.sh` | Poll `/health` until the app returns 200 with db connected |

## Two deployment targets (they coexist)

| Target | Entry point | When to use |
| ------ | ----------- | ----------- |
| **EC2 + Docker Compose** | `deploy-ec2.sh` | Default. SSM deploy pointer + ASG rolling refresh. |
| **EKS (Kubernetes)** | `deploy-eks.sh` | When Terraform was applied with `enable_eks=true`. Opt-in via `DEPLOY_EKS=true` (GitHub repo variable) or the `DEPLOY_EKS` Jenkins parameter. |

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
