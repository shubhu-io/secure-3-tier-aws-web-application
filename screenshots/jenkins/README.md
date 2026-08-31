# Jenkins Step Screenshots — Image Ideas

Place images here: `screenshots/jenkins/*.png`

## Ideas — generate these Jenkins UI captures (`../IMAGE_IDEAS.md`)

1. `01-jenkins-provision.png` — `terraform apply enable_jenkins=true` → `jenkins_url`
2. `02-jenkins-unlock.png` — Unlock Jenkins (password from `aws ssm ... /var/log/jenkins-init.log`)
3. `03-jenkins-plugins.png` — Install suggested plugins
4. `04-jenkins-credentials-aws.png` — Manage Credentials → AWS / GitHub
5. `05-jenkins-agent-docker.png` — Agent `docker` online
6. `06-jenkins-ci-pipeline.png` — `Jenkinsfile-ci` green stages
7. `07-jenkins-deploy-pipeline.png` — `Jenkinsfile` deploy stages (ECR → ASG refresh → smoke)
8. `08-jenkins-build-log.png` — Console log + Trivy scan output
9. `09-jenkins-asg-refresh.png` — ASG Activity post-Jenkins deploy

Doc link: `![Screenshot: Jenkins deploy](../../screenshots/jenkins/07-jenkins-deploy-pipeline.png)` in `docs/deployment/jenkins.md`

Generate → drop here → I will wire into docs/jenkins steps.
