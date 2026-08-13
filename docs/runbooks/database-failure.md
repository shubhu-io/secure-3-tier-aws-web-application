# Runbook — Database Failure

## Purpose
Recover when Amazon RDS is unavailable, degraded, or the app cannot reach it.

## When to use
- `/health` reports `"db":"disconnected"`.
- RDS alarms fire (CPU / storage).
- The app logs show `ECONNREFUSED` / `ETIMEDOUT` to the DB host.
- The RDS status is `creating`, `deleting`, `storage-full`, or `failed`.

## Prerequisites
- AWS CLI access. DB snapshot/snapshot-restore permissions.

## Symptoms
- Backend logs: `connect ECONNREFUSED 10.0.21.x:5432` or `timeout expired`.
- `/health` → `db: disconnected` (health endpoint stays 200 by design; use `/health/ready` for the readiness signal).
- `rds-cpu-high` / `rds-storage-low` alarms.

## Diagnosis
```bash
aws rds describe-db-instances \
  --db-instance-identifier secure-ntier-<env>-db --region <region> \
  --query 'DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,PubliclyAccessible:PubliclyAccessible,StorageEncrypted:StorageEncrypted}'

# recent events
aws rds describe-events --source-type db-instance \
  --source-identifier secure-ntier-<env>-db --region <region> \
  --query 'Events[0:10].{Date:Date,Message:Message}'
```

## Recovery

### Case 1 — RDS is simply unreachable from the app
Check connectivity + config:
- Secret host in Secrets Manager matches the RDS endpoint.
- DB SG allows 5432 from the app SG.
- The instance can reach the DB subnet (check flow logs for REJECTs on 5432).
Then trigger an instance refresh so instances re-read the secret.

### Case 2 — RDS instance failed but Multi-AZ is on (prod)
RDS fails over automatically (~1-2 min). Verify:
```bash
aws rds describe-db-instances \
  --db-instance-identifier secure-ntier-<env>-db --region <region> \
  --query 'DBInstances[0].DBInstanceStatus'   # expect: available
```
The app reconnects on the next pool query. No manual action needed.

### Case 3 — Instance is `storage-full` / corrupted — restore
1. Optionally stop app writes (scale ASG to 0).
2. Choose the recovery point:
   - **Latest (point-in-time):**
     ```bash
     aws rds restore-db-instance-to-point-in-time \
       --source-db-instance-identifier secure-ntier-<env>-db \
       --target-db-instance-identifier secure-ntier-<env>-db-restored \
       --restore-time <timestamp> --region <region>
     ```
   - **A specific snapshot:**
     ```bash
     aws rds restore-db-instance-from-db-snapshot \
       --db-instance-identifier secure-ntier-<env>-db-restored \
       --db-snapshot-identifier <snapshot> \
       --db-subnet-group-name secure-ntier-<env>-db-subnet-group --region <region>
     ```
3. Update the DB secret host in Secrets Manager to the new endpoint.
4. Trigger an instance refresh (instances read the new host).
5. Verify `/health` → `db: connected`.

## Verification
- `aws rds describe-db-instances` → `available`.
- `/health` → `"db":"connected"`.
- App writes/reads succeed (`tests/application/integration.sh`).

## Escalation
If restore fails or data loss is significant, escalate to platform/DBA team
with: the RDS events, the backup window/snapshot inventory, and the chosen
recovery point.

## Post-incident actions
- Confirm automated backups ran for the retention period.
- Restore into a sandbox if you need to inspect lost data.
- Consider tightening `storage` autoscaling threshold.
