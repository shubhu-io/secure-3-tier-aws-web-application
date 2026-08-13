# Jenkins CI/CD (alternative to GitHub Actions)

This project ships **two** CI/CD engines that do the same thing:

| Engine | File | Best for |
| ------ | ---- | -------- |
| GitHub Actions | `.github/workflows/ci.yml` + `deploy.yml` | GitHub-hosted, zero infra |
| **Jenkins** | `cicd/Jenkinsfile` + this guide | self-hosted, existing Jenkins, on-prem |

Both pipelines are thin wrappers around the exact same shell scripts under
`cicd/scripts/`, so a deploy from Jenkins is byte-identical to a deploy from
GitHub Actions.

> Pick one and keep it green. Running both on the same branch will fight over
> the SSM "deploy pointer" (last writer wins). In a team, standardise on one.

---

## What the Jenkinsfile does

```text
Checkout → Backend test+audit → Frontend build
        → Docker build → Trivy scan (CRITICAL/HIGH gate)
        → ECR login → Push backend:tag → Push frontend:tag
        → deploy-ec2 (SSM pointer + instance refresh)
        → Smoke test against ALB (optional)
```

It mirrors `.github/workflows/deploy.yml` stage-for-stage.

---

## 1. Prerequisites on the Jenkins controller

- Jenkins ≥ 2.346 with the plugins:
  - **Pipeline**
  - **Credentials Binding**
  - **Docker** (pipeline step) — optional, we use `sh` + Docker CLI instead
  - **Timestamper** (cosmetic)
- A Linux **agent** labelled `docker && linux` with:
  - `bash`, `git`, `docker`, `curl`, `jq`
  - AWS CLI **v2** (`aws` on PATH)
  - `/var/run/docker.sock` available (Trivy stage reads local images)

---

## 2. AWS credentials in Jenkins

1. **Manage Jenkins → Credentials → Global → Add Credentials**
2. Type: `Username with password`
   - Username = your **AWS Access Key ID**
   - Password = your **AWS Secret Access Key**
   - ID = `aws-keys` (the Jenkinsfile references this ID)

> Least-privilege: attach the CI/CD IAM policy
> `security/iam/cicd-policy.json` (also created by Terraform — see the
> `cicd_policy_arn` output) to the user that owns these keys.

---

## 3. Create the pipeline job

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

---

## 4. GitHub → Jenkins webhook (optional)

1. GitHub repo → **Settings → Webhooks → Add webhook**
2. Payload URL: `https://<YOUR_JENKINS>/github-webhook/`
3. Content type: `application/json`, events: **Just the push event**.
4. In Jenkins, enable **GitHub hook trigger for GITScm polling** on the job.

---

## 5. Parameters

| Parameter | Default | Meaning |
| --------- | ------- | ------- |
| `ENVIRONMENT` | `dev` | `dev` / `prod` — controls ECR/SSM/ASG naming |
| `REGION` | `eu-west-1` | AWS region |
| `PROJECT` | `secure-ntier` | name prefix used everywhere |
| `AUTO_DEPLOY` | `true` | `false` = build+scan only (dry run, no push/deploy) |
| `IMAGE_TAG` | *(empty)* | override the tag; empty = current git SHA |
| `ALB_URL` | *(empty)* | run a smoke test against this URL after deploy |

---

## 6. Manual run (equivalent to pipeline, no Jenkins)

The scripts the pipeline calls are the same ones you can run by hand:

```bash
# build + scan
docker build -f docker/backend/Dockerfile  -t secure-ntier-backend:ci . &&
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --ignore-unfixed --exit-code 1 \
  --severity CRITICAL,HIGH secure-ntier-backend:ci

# deploy a specific commit
bash cicd/scripts/ecr-login.sh eu-west-1
bash cicd/scripts/build-and-push.sh backend 1a2b3c4d eu-west-1 secure-ntier dev
bash cicd/scripts/build-and-push.sh frontend 1a2b3c4d eu-west-1 secure-ntier dev
bash cicd/scripts/deploy-ec2.sh 1a2b3c4d eu-west-1 dev secure-ntier
ALB_URL="http://..." ATTEMPTS=36 bash cicd/scripts/smoke-test.sh
```

---

## 7. Pipeline-as-code hygiene

- Keep the Jenkinsfile **thin**: all real logic lives in `cicd/scripts/`
  so it is shared with the GitHub Actions path and is testable locally.
- The pipeline **must** contain the security gates (npm audit, Trivy
  CRITICAL/HIGH) or it is not this pipeline — never delete them.
- Version the Jenkinsfile through Git review like any code.

---

## Troubleshooting

| Symptom | Cause / fix |
| ------- | ----------- |
| `docker: command not found` | agent lacks Docker; install it or re-label |
| `Credentials 'aws-keys' not found` | create the global credential with ID `aws-keys` |
| `403 Authorization failed` on webhook | GitHub webhook URL must include `/github-webhook/` |
| Trivy can't find the image | the `-v /var/run/docker.sock` mount is missing |
| Smoke test times out | check `describe-assg` for the instance refresh status; the new image may not have caught up |