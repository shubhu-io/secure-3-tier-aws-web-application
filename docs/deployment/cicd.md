# CI/CD Setup Guide

## Repository secrets

GitHub Actions needs the following **secrets** (Settings → Secrets and
variables → Actions → New repository secret):

| Secret | Value |
| ------ | ----- |
| `AWS_ACCESS_KEY_ID` | Access key of the CI/CD IAM user |
| `AWS_SECRET_ACCESS_KEY` | Matching secret key |
| `AWS_REGION` | `ap-south-1` (your region) |
| `ALB_URL` | `http://<your-alb-dns>` from `terraform output alb_dns_name` (or `https://app.example.com`) |
| `ECR_PROJECT` | `secure-ntier` (must match `project_name`) |
| `ECR_ENV` | `dev` (must match `environment`) |

The CI/CD IAM user needs the least-privilege policy in
[`security/iam/cicd-policy.json`](../../security/iam/cicd-policy.json)
(Terraform also creates this policy and prints its ARN — attach that instead).

## Enable the workflows

The workflows live in `.github/workflows/` and are enabled automatically once
your repository is on GitHub. Both are **driven by `stack.json`** — every stage
loops over the manifest, so a new service only needs a `stack.json` entry.

| Workflow | Trigger | Effect |
| -------- | ------- | ------ |
| `ci.yml` | PRs + pushes to `develop` | Gates merges: manifest validate → per-service test/build/scan → Terraform validate |
| `deploy.yml` | push to `main` | Deploys to AWS: build+push every service → SSM → instance refresh → smoke test |

> **Jenkins alternative?** The same pipelines exist as `cicd/Jenkinsfile` +
> `cicd/Jenkinsfile-ci`. Provision a controller with the Terraform Jenkins
> module (`enable_jenkins = true`) — see [`docs/deployment/jenkins.md`](./jenkins.md).

## Run your first deployment

```bash
git add .
git commit -m "feat: initial n-tier platform"
git push -u origin main
```

Then: GitHub → your repo → **Actions** → the `Deploy` workflow.

Expected flow:

```text
stack-validate ✔ → CI per service (tests + audit + build + trivy) ✔
→ ECR login ✔ → Build + push every service ✔ → Update params + instance refresh ✔
→ Smoke test ✔ → Done
```

After it finishes, verify the app:

```bash
curl -s <ALB_URL>/health
# {"status":"ok","db":"connected",...}
```

## Instance refresh details

The pipeline updates the SSM parameters with `:<git-sha>`-tagged image URIs
(**one parameter per service**, read from `stack.json`), then calls:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name secure-ntier-dev-asg \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":120}'
```

Watch progress:

```bash
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name secure-ntier-dev-asg --region <region>
```

## If the pipeline fails

| Stage | Common cause | Fix |
| ----- | ------------ | --- |
| Configure AWS credentials | Wrong/expired keys | Re-check the secrets |
| ECR login / push | IAM policy missing ECR push | Attach the CI/CD policy |
| SSM put-parameter | Policy missing SSM write | Attach the CI/CD policy |
| Instance refresh | Wrong ASG name | Check `ECR_PROJECT`/`ECR_ENV` match Terraform |
| Smoke test | App not healthy in time | Check `ALB_URL`; look at CloudWatch logs |

Full troubleshooting: [`docs/operations/troubleshooting.md`](../operations/troubleshooting.md).

## (Recommended) Harden CI access with OIDC

Long-lived keys are fine for learning. In production, use **GitHub OIDC** so
Actions requests short-lived, scoped credentials automatically. The workflow
only needs to change the credential step. (Documented as a future
improvement.)
