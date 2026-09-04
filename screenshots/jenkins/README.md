# Jenkins CI/CD Automation Screenshots

This folder contains screenshots validating the automated Jenkins CI/CD controller, agent infrastructure, and pipeline executions deployed on AWS EC2 in `ap-south-1`.

---

## 📋 Recommended Captures

| Filename | Description | Context |
|---|---|---|
| `01-jenkins-provision.png` | Terraform completion exposing the secure Jenkins controller endpoint | Infrastructure Deployment |
| `02-jenkins-unlock.png` | Initial administrator unlock screen with SSM-retrieved credentials | Controller Setup |
| `03-jenkins-plugins.png` | Standardized plugin installation progress | Environment Bootstrap |
| `04-jenkins-credentials-aws.png` | Configured Jenkins credential store with IAM role access | Credential Management |
| `05-jenkins-agent-docker.png` | Dynamic Docker execution agent online and connected | Build Infrastructure |
| `06-jenkins-ci-pipeline.png` | Multi-stage `Jenkinsfile-ci` execution passing all quality gates | Continuous Integration |
| `07-jenkins-deploy-pipeline.png` | Automated continuous deployment pipeline with rolling update | Continuous Delivery |
| `08-jenkins-build-log.png` | Console output verifying automated Trivy container vulnerability scan | DevSecOps Gate |
| `09-jenkins-asg-refresh.png` | AWS Auto Scaling Group Instance Refresh triggered by pipeline | Release Management |

Refer to [`docs/deployment/jenkins.md`](../../docs/deployment/jenkins.md) for full pipeline configuration details.
