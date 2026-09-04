# Self-hosted Jenkins (alternative CI/CD engine)

This guide provisions a self-hosted **Jenkins controller** on EC2 with
Terraform and wires it up as the **alternative CI/CD engine** to GitHub
Actions. Both engines run the exact same `cicd/scripts/` — so a build from
Jenkins is byte-identical to one from GitHub Actions.

> ⚠️ **COST WARNING** — a `t3.medium` Jenkins box is ~$15–25/month. It **overlaps**
> GitHub Actions (both deploy the same branch). Pick **one** engine as your
> source of truth. If you only want CI/CD and use GitHub, skip this guide.

## What you get

| Piece | What it is |
| ----- | ---------- |
| `terraform/cloud/<cloud>/modules/jenkins/` | EC2 controller + SG (UI 8080, agents 50000) + IAM role reusing the CI/CD policy |
| `cicd/Jenkinsfile` | **Deploy** pipeline (CI → ECR push → SSM → ASG refresh → optional EKS → smoke test) |
| `cicd/Jenkinsfile-ci` | **CI** pipeline (manifest validate → per-service test/build/scan → Terraform fmt/validate) — mirrors `.github/workflows/ci.yml` |
| `stack.json` | The manifest both pipelines read — one entry per service, zero pipeline edits |

The controller runs a **container** (Jenkins LTS + AWS CLI v2 + kubectl + Docker
CLI) on an EC2 instance. Its built-in node is the `docker && linux` agent; the
pipeline reaches AWS through the instance role via IMDSv2 — **no long-lived
keys are needed on the box**.

## 1. Provision the controller

In your environment file (e.g. `terraform/environments/dev/terraform.tfvars`):

```hcl
enable_jenkins        = true
jenkins_ingress_cidrs = ["203.0.113.5/32"]   # LOCK THIS DOWN to your IP(s)!
# jenkins_key_name    = "my-key"             # optional SSH key; empty = SSM Session Manager
# jenkins_instance_type = "t3.medium"        # default
# jenkins_kubectl_version = "v1.31.0"        # match your EKS cluster, if any
```

Then apply:

```bash
cd terraform
terraform init -backend-config="environments/dev/backend.hcl"
terraform plan -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan
terraform apply plan.tfplan

terraform output jenkins_url          # http://<PUBLIC_IP>:8080
terraform output jenkins_public_ip
```

> Default `jenkins_ingress_cidrs = ["0.0.0.0/0"]` is a **lab-only** default —
> the UI has no auth until you unlock it. Lock the CIDR to your IPs for anything
> real.

## 2. Initial setup (first boot)

The user-data script builds the controller image and starts it on first boot
(`/var/log/jenkins-init.log` records the one-time admin password):

```bash
aws ssm start-session --target <INSTANCE_ID> --region <region>
sudo tail -f /var/log/jenkins-init.log      # or: cat /var/log/jenkins-init.log
```

Then, in the browser:

1. Open `http://<PUBLIC_IP>:8080`, paste the **initial admin password** from the
   log, and install the suggested plugins.
2. **Manage Jenkins → Nodes → built-in node**: add the labels **`docker`** and
   **`linux`** (and raise executors to 2). The pipelines target
   `agent { label 'docker && linux' }`.
3. **Optional** — credentials:
   - **Manage Jenkins → Credentials → Global**, add two **Secret text**
     credentials: `aws-access-key-id` and `aws-secret-access-key`.
   - If you **skip** them, the pipeline automatically uses the controller's AWS
     **instance role** (the Jenkins module attaches the CI/CD policy) — keys are
     never stored anywhere.

## 3. Create the pipeline jobs

Both pipelines are **Pipeline script from SCM** pointing at this repo:

| Job | Script Path | Branch | Purpose |
| --- | ----------- | ------ | ------- |
| `secure-ntier-ci` | `cicd/Jenkinsfile-ci` | `*/develop`, PR builds | Gate changes: validate `stack.json`, CI every service, Terraform fmt/validate |
| `secure-ntier-deploy` | `cicd/Jenkinsfile` | `*/main` | Ship: CI → ECR push → SSM pointer → ASG refresh → (optional EKS) → smoke test |

Job config (both):

1. **New Item → Pipeline**
2. **Pipeline → Definition: Pipeline script from SCM**
   - SCM: `Git`, Repository URL: your repo, Branch Specifier per table above
   - Script Path: `cicd/Jenkinsfile` or `cicd/Jenkinsfile-ci`
3. **Build Triggers** (deploy job):
   - **GitHub hook trigger for GITScm polling** → GitHub webhook at
     `https://<JENKINS>/github-webhook/`, or Poll SCM (`H/5 * * * *`), or manual
     (the pipeline is parameterized).
4. Save.

### Deploy job parameters

| Parameter | Default | Meaning |
| --------- | ------- | ------- |
| `ENVIRONMENT` | `dev` | `dev` / `prod` — ECR/SSM/ASG naming |
| `REGION` | `ap-south-1` | AWS region |
| `PROJECT` | `secure-ntier` | name prefix |
| `AUTO_DEPLOY` | `true` | `false` = build + scan only (no push/deploy) |
| `IMAGE_TAG` | *(empty)* | override; empty = git SHA |
| `ALB_URL` | *(empty)* | smoke test target after deploy |
| `DEPLOY_EKS` | `false` | also deploy to EKS (needs `enable_eks=true` + kubectl) |
| `K8S_CLUSTER` | *(empty)* | EKS cluster; empty = `<project>-<env>-eks` |

## 4. GitHub → Jenkins webhook (optional)

1. GitHub repo → **Settings → Webhooks → Add webhook**
2. Payload URL: `https://<JENKINS>/github-webhook/`
3. Content type `application/json`, events: **Just the push event**.
4. Enable **GitHub hook trigger for GITScm polling** on the job.

## 5. How both pipelines stay in sync

`stack.json` is the single source of truth for the tech stack. Every stage loops
over the manifest:

```text
stack-validate.sh   validate the manifest (names, ports, dockerfiles exist, 1 public service)
stack-ci.sh         for each service: ci_steps in toolchain → docker build → trivy scan
stack-push.sh       for each service: build + push to ECR (tags :sha + :latest)
deploy-ec2.sh       for each service: update SSM image pointer → ASG instance refresh
deploy-eks.sh       render k8s manifests per service → apply → roll → smoke test
```

Adding a service = one `stack.json` entry. No GitHub Actions or Jenkinsfile
edits.

## Manual run (no Jenkins needed)

The same scripts the pipelines call run by hand:

```bash
bash cicd/scripts/stack-validate.sh
bash cicd/scripts/stack-ci.sh                      # local build + scan
bash cicd/scripts/ecr-login.sh ap-south-1
bash cicd/scripts/stack-push.sh <git-sha> ap-south-1 secure-ntier dev
bash cicd/scripts/deploy-ec2.sh <git-sha> ap-south-1 dev secure-ntier
ALB_URL="http://..." ATTEMPTS=36 bash cicd/scripts/smoke-test.sh
```

## Troubleshooting

| Symptom | Cause / fix |
| ------- | ----------- |
| Can't open `:8080` | SG ingress; check `jenkins_ingress_cidrs` |
| `docker: command not found` | the agent node needs labels `docker` + `linux` |
| `Credentials 'aws-access-key-id' not found` | expected — pipeline falls back to the instance role; or create the credential |
| Pipeline can't auth to AWS | instance role missing the CI/CD policy — it is attached by the module; re-apply |
| Trivy can't find the image | the `-v /var/run/docker.sock` mount is missing on the agent |
| Smoke test times out | check `describe-instance-refreshes`; new images may not have caught up |

## Cleanup

```bash
# remove the controller (cost stops immediately)
cd terraform
terraform apply -var-file="environments/dev/terraform.tfvars"   # after enable_jenkins = false
# or destroy everything
terraform destroy -var-file="environments/dev/terraform.tfvars"
```