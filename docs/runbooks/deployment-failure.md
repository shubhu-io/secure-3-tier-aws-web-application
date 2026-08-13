# Runbook — Deployment Failure

## Purpose
Recover from a failed application deployment (pipeline red, or the app breaks
after a successful pipeline run).

## When to use
- `deploy.yml` fails at any stage.
- The pipeline passed but `/health` reports problems after the deploy.
- The app is running the wrong version.

## Prerequisites
- AWS CLI configured with an account that can read SSM/ASG/ECR.
- Access to GitHub Actions logs.
- Optional: SSM Session Manager access to the instances.

## Symptoms
- Red X in GitHub Actions.
- `curl <ALB_URL>/health` → non-200, or `db: disconnected`.
- Target group shows unhealthy targets after a refresh.

## Diagnosis
```bash
# Which image is the environment pointed at?
aws ssm get-parameter --name "/secure-ntier/<env>/backend-image" --region <region> --query Parameter.Value --output text

# Is an instance refresh running / stuck?
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name secure-ntier-<env>-asg --region <region>

# Are the targets healthy?
aws elbv2 describe-target-health --target-group-arn <tg> --region <region>

# App logs (needs SSM session or CloudWatch)
# CloudWatch Logs → /secure-ntier-<env>/app → backend stream
```

## Recovery
1. **Pipeline failed before deploy** → fix the failing stage (usually tests or
   scan), push again. Nothing was deployed.
2. **Pipeline failed during deploy** (ECR/SSM/refresh) → confirm the images
   actually made it:
   ```bash
   aws ecr describe-images --repository-name secure-ntier-<env>-backend --region <region>
   ```
   If the image exists, rerun only the deploy step (or `bash scripts/deploy.sh <sha> <region> secure-ntier <env>`).
3. **Deployed but broken** → **roll back** (see `rollback.md`):
   ```bash
   aws ssm put-parameter --name "/secure-ntier/<env>/backend-image" --type String --value "<previous-good-uri>" --overwrite --region <region>
   # repeat for frontend, then:
   aws autoscaling start-instance-refresh --auto-scaling-group-name secure-ntier-<env>-asg --region <region>
   ```

## Verification
- `curl <ALB_URL>/health` returns `200` with `"db":"connected"`.
- Target group shows all targets `healthy`.
- The SSM parameter points at the intended image SHA.

## Escalation
If the rollback also fails (e.g. instances can't boot), escalate to the
platform team with: pipeline log links, the SHAs of good/bad images, and the
target-health output.

## Post-incident actions
- Root cause analysis: what broke (code vs image vs infra)?
- Add a test/scan that would have caught it.
- Update the runbook with anything new you learned.
