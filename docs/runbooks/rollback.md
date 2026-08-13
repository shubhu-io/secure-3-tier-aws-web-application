# Runbook — Rollback

## Purpose
Return the application to the last known-good version quickly.

## When to use
- A deploy breaks the app (502s, unhealthy targets, errors in logs).
- The pipeline is green but the smoke test reveals problems, or users report
  a regression after a deploy.

## Prerequisites
- AWS CLI with permission to write SSM parameters and start instance
  refreshes (the CI/CD policy covers this).
- Knowledge of the last known-good image SHA (available in GitHub releases,
  previous pipeline runs, or ECR).

## Symptoms
- `/health` broken after a deploy.
- Elevated 5xx errors or unhealthy targets.
- Backend errors referencing the new code path.

## Diagnosis
```bash
# what's pointed where now
aws ssm get-parameter --name "/secure-ntier/<env>/backend-image" --region <region> --query Parameter.Value --output text

# image history (to find the last good SHA)
aws ecr describe-images --repository-name secure-ntier-<env>-backend --region <region> \
  --query 'sort_by(imageDetails, &imagePushedAt)[-10:].{Tags:imageTags,PushedAt:imagePushedAt}'
```

## Recovery — rolling back
1. **Reuse the deploy mechanism** (never hand-roll images):
   ```bash
   bash cicd/scripts/deploy-ec2.sh <LAST_GOOD_SHA> <region> <env> <project>
   ```
   This writes the old SHA to both SSM parameters and starts a rolling
   instance refresh.
2. Wait for the refresh (`describe-instance-refreshes` → `Successful`).
3. Confirm:
   ```bash
   curl <ALB_URL>/health
   bash tests/application/integration.sh <ALB_URL>
   ```

> Note: the DB schema is forward-only here (the app runs `CREATE TABLE IF NOT
> EXISTS`). If a release introduced destructive DB changes, rolling back the
> app may not be enough — restore the DB too (see `database-failure.md`).

## Verification
- SSM parameters point at the last-good SHA.
- `/health` returns 200 + `db: connected`.
- Integration tests pass.
- No 5xx spike on the ALB dashboard.

## Escalation
If the last-good version also fails, escalate to the platform team (this
usually means infra/DB, not the app).

## Post-incident actions
- Preserve the bad SHA + failure logs for analysis.
- Write a regression test that would have caught the bug.
- Decide: fix forward (new deploy) or stay on the old version.
- Record the incident and time-to-recover in the incident log.
