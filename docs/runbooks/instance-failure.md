# Runbook — EC2 Instance Failure

## Purpose
Recover when one (or all) application instances fail.

## When to use
- An instance is stopped/terminated/failing status checks.
- The target group shows `unhealthy` targets.
- The ASG is launching replacements repeatedly (churn).

## Prerequisites
- AWS CLI access. Optional SSM access to instances for diagnosis.

## Symptoms
- `aws autoscaling describe-auto-scaling-groups` shows fewer instances than desired.
- ALB returns 502/503 intermittently.
- `UnHealthyHostCount` alarm fires.

## Diagnosis
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name secure-ntier-<env>-asg --region <region> \
  --query 'AutoScalingGroups[0].{Instances:Instances,Status:Status}'

aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name secure-ntier-<env>-asg --region <region> \
  --query 'Activities[0:5].{Description:Description,Cause:Cause,StatusCode:StatusCode}'

aws elbv2 describe-target-health --target-group-arn <tg> --region <region>
```

## Recovery
The ASG does the recovery automatically. Your job is to **confirm** it and
**diagnose why** if it can't:

1. If an instance was terminated → the ASG should already be replacing it. Wait ~5 min.
2. If replacement instances keep failing:
   ```bash
   # boot log
   aws ec2 describe-instances --instance-ids <id> --region <region> \
     --query 'Reservations[0].Instances[0].{State:State.Name,Reason:StateReason}'
   # app log via SSM:
   aws ssm start-session --target <id> --region <region>
   #   sudo cat /var/log/user-data.log
   #   sudo docker compose -f /opt/app/docker-compose.yml ps
   ```
3. Common root causes and fixes:
   - Container crashes on boot → fix image/config → redeploy.
   - ECR pull fails → check the instance role ECR permissions.
   - Can't reach DB → check DB SG / secret host.
4. If the ASG itself is broken (e.g. launch template references a deleted AMI) → fix the Terraform, `terraform apply`, wait for refresh.

## Verification
- Instance count returns to `desired_capacity` and is stable.
- All targets `healthy` in the target group.
- `/health` returns 200.

## Escalation
If the ASG cannot keep a single healthy instance, escalate with: scaling
activities output, user-data logs, and the launch template version in use.

## Post-incident actions
- Determine *why* the instance failed (hardware vs software).
- Add a health check / alarm if the failure was silent.
- Update the runbook if a new failure mode was discovered.
