# Operations — Backup & Recovery

## What is backed up

| Component | Backup | Where |
| --------- | ------ | ----- |
| Database | Automated snapshots daily + transaction logs | RDS, retention `backup_retention_days` |
| Database | Manual snapshots on demand | RDS snapshots |
| Infrastructure | Terraform state | S3 (versioned) |
| Code | Git history | GitHub |
| Containers | ECR images (last 10 per repo) | ECR lifecycle policy |

## RDS automated backups

Enabled whenever `backup_retention_days > 0`. AWS takes:

- A full daily snapshot during the backup window (03:00-04:00).
- Transaction logs every ~5 minutes, enabling point-in-time restore.

## Manual snapshot before risky work

Before a destructive migration or a code change that touches the schema:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier secure-ntier-dev-db \
  --db-snapshot-identifier secure-ntier-dev-pre-release-$(date +%Y%m%d%H%M) \
  --region <region>
```

List snapshots:

```bash
aws rds describe-db-snapshots \
  --db-instance-identifier secure-ntier-dev-db --region <region>
```

## Restore a database

**Point-in-time (recommended, most recent):**

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier secure-ntier-dev-db \
  --target-db-instance-identifier secure-ntier-dev-db-restored \
  --restore-time <ISO-timestamp> \
  --region <region>
```

**From a snapshot:**

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier secure-ntier-dev-db-restored \
  --db-snapshot-identifier <snapshot-id> \
  --db-subnet-group-name secure-ntier-dev-db-subnet-group \
  --region <region>
```

After restore:

1. Update the secret in Secrets Manager with the new host.
2. Trigger an instance refresh so instances pick up the new endpoint.
3. Verify `/health` shows `db: connected`.

> ⚠️ `skip_final_snapshot = true` in dev means **destroy removes all data**
> with no final snapshot. Keep it `false` in prod.

## Rebuilding the whole platform

The complete recovery path is in
[`docs/architecture/disaster-recovery.md`](../architecture/disaster-recovery.md).

## Verification checklist

- [ ] A manual snapshot can be created.
- [ ] You know how to restore (practiced at least once).
- [ ] State bucket versioning is ON.
- [ ] Prod has `deletion_protection = true` and `skip_final_snapshot = false`.
