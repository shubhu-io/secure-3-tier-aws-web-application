# Jenkins CI/CD (alternative to GitHub Actions)

This project ships **two** CI/CD engines that do the same thing:

| Engine | File | Best for |
| ------ | ---- | -------- |
| GitHub Actions | `.github/workflows/ci.yml` + `deploy.yml` | GitHub-hosted, zero infra |
| **Jenkins** | `cicd/Jenkinsfile` + `cicd/Jenkinsfile-ci` + this guide | self-hosted, existing Jenkins, on-prem |

Both engines are thin wrappers around the **same** shell scripts in
`cicd/scripts/`, which read the **`stack.json` manifest** (single source of
truth for the tech stack). A deploy from Jenkins is byte-identical to one from
GitHub Actions, and a new service needs **only a `stack.json` entry** — no
pipeline edits.

> Pick one and keep it green. Running both on the same branch will fight over
> the SSM "deploy pointer" (last writer wins). In a team, standardise on one.

---

## What the pipelines do

**`cicd/Jenkinsfile`** — deploy (push to `main`), mirrors `.github/workflows/deploy.yml`:

```text
Checkout → CI per service (test + audit + build + trivy, via stack.json)
        → ECR login → Push every service (stack-push)
        → deploy-ec2 (SSM pointer + instance refresh)
        → deploy-eks (optional, when DEPLOY_EKS=true)
        → Smoke test against ALB (optional)
```

**`cicd/Jenkinsfile-ci`** — CI (PRs / develop), mirrors `.github/workflows/ci.yml`:

```text
Checkout → stack-validate (manifest) → CI per service (stack-ci)
        → Terraform fmt + validate
```

No AWS credentials are needed for the CI pipeline — nothing is pushed.

---

## 1. Prerequisites on the Jenkins controller

- Jenkins ≥ 2.346 with the plugins:
  - **Pipeline**
  - **Credentials Binding**
  - **Docker** (pipeline step) — optional, we use `sh` + Docker CLI instead
  - **Timestamper** (cosmetic)
- A Linux **agent** labelled `docker && linux` with:
  - `bash`, `git`, `docker`, `curl`, **`jq`** (the stack scripts read the manifest)
  - AWS CLI **v2** (`aws` on PATH)
  - `/var/run/docker.sock` available (Trivy stage reads local images)
  - `kubectl` on PATH — **only** required if you enable `DEPLOY_EKS`

> The Terraform **Jenkins module** (`terraform/cloud/<cloud>/modules/jenkins/`, opt-in via
> `enable_jenkins`) provisions this controller for you, including an IAM role
> with the CI/CD policy. See [`docs/deployment/jenkins.md`](../../docs/deployment/jenkins.md).

---

## 2. AWS credentials in Jenkins (OPTIONAL)

The deploy pipeline works **without any stored credentials** — it falls back to
the agent's AWS **instance role** (IMDSv2). To use explicit keys instead:

1. **Manage Jenkins → Credentials → Global → Add Credentials**
2. Type: **Secret text** ×2
   - ID = `aws-access-key-id`   (your AWS Access Key ID)
   - ID = `aws-secret-access-key` (your AWS Secret Access Key)
3. The pipeline detects them and prefers them; otherwise it logs
   "using the agent's AWS instance role".

> Least-privilege: attach the CI/CD IAM policy
> `security/iam/cicd-policy.json` (also created by Terraform — see the
> `cicd_policy_arn` output) to the user that owns these keys.

---

## 3. Create the pipeline jobs

**Deploy job:**

1. **New Item → Pipeline** (e.g. `secure-ntier-deploy`).
2. **Pipeline** section → Definition: **Pipeline script from SCM**
   - SCM: `Git`
   - Repository URL: your repo
   - Script Path: `cicd/Jenkinsfile`
   - Branch Specifier: `*/main`
3. **Build Triggers** (choose one):
   - **GitHub hook trigger for GITScm polling** → point the GitHub webhook at
     `https://<jenkins>/github-webhook/`
   - or **Poll SCM** with a cron like `H/5 * * * *`
   - or trigger manually — the pipeline has parameters.
4. Save.

**CI job** (optional, same steps): Script Path `cicd/Jenkinsfile-ci`, Branch
Specifier `*/develop`, no parameters.

---

## 4. GitHub → Jenkins webhook (optional)

1. GitHub repo → **Settings → Webhooks → Add webhook**
2. Payload URL: `https://<YOUR_JENKINS>/github-webhook/`
3. Content type: `application/json`, events: **Just the push event**.
4. In Jenkins, enable **GitHub hook trigger for GITScm polling** on the job.

---

## 5. Deploy-job parameters

| Parameter | Default | Meaning |
| --------- | ------- | ------- |
| `ENVIRONMENT` | `dev` | `dev` / `prod` — controls ECR/SSM/ASG naming |
| `REGION` | `ap-south-1` | AWS region |
| `PROJECT` | `secure-ntier` | name prefix used everywhere |
| `AUTO_DEPLOY` | `true` | `false` = build+scan only (dry run, no push/deploy) |
| `IMAGE_TAG` | *(empty)* | override the tag; empty = current git SHA |
| `ALB_URL` | *(empty)* | run a smoke test against this URL after deploy |
| `DEPLOY_EKS` | `false` | also deploy to EKS (needs `enable_eks=true` in Terraform + `kubectl` on the agent) |
| `K8S_CLUSTER` | *(empty)* | EKS cluster name; empty = `<project>-<env>-eks` |

---

## 6. Manual run (equivalent to the pipeline, no Jenkins)

The scripts the pipelines call are the same ones you can run by hand:

```bash
# CI for every service (local images, no AWS): manifest → toolchain tests → build → trivy
bash cicd/scripts/stack-validate.sh
bash cicd/scripts/stack-ci.sh

# deploy a specific commit
bash cicd/scripts/ecr-login.sh ap-south-1
bash cicd/scripts/stack-push.sh 1a2b3c4d ap-south-1 secure-ntier dev
bash cicd/scripts/deploy-ec2.sh 1a2b3c4d ap-south-1 dev secure-ntier
ALB_URL="http://..." ATTEMPTS=36 bash cicd/scripts/smoke-test.sh

# or deploy to EKS instead (or as well)
bash cicd/scripts/deploy-eks.sh 1a2b3c4d ap-south-1 dev secure-ntier
```

---

## 7. Pipeline-as-code hygiene

- Keep the Jenkinsfiles **thin**: all real logic lives in `cicd/scripts/`
  so it is shared with the GitHub Actions path and is testable locally.
- The pipeline **must** contain the security gates (npm audit, Trivy
  CRITICAL/HIGH) or it is not this pipeline — never delete them.
- Version the Jenkinsfiles through Git review like any code.

---

## Troubleshooting

| Symptom | Cause / fix |
| ------- | ----------- |
| `docker: command not found` | agent lacks Docker; install it or re-label `docker && linux` |
| `jq: command not found` | the stack scripts need `jq` on the agent |
| `Credentials 'aws-access-key-id' not found` | **expected** — the pipeline logs a warning and uses the agent's AWS instance role; or create the credential |
| `403 Authorization failed` on webhook | GitHub webhook URL must include `/github-webhook/` |
| Trivy can't find the image | the `-v /var/run/docker.sock` mount is missing |
| Smoke test times out | check `describe-instance-refreshes` for the instance refresh status; the new image may not have caught up |