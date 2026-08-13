# WAF Configuration

The WAF web ACL is created by Terraform in the ALB module
(`terraform/modules/alb/main.tf`). This file documents the rules and the
rationale. All rules use **AWS Managed Rule Groups** so AWS maintains the
signatures — no custom rules to manage.

## Rules

| Priority | Managed rule group | Protects against |
| -------- | ------------------ | ---------------- |
| 1 | `AWSManagedRulesCommonRuleSet` | SQL injection, XSS, LFI/RFI, PHP/RCE payloads, bad headers, generic abuse |
| 2 | `AWSManagedRulesSQLiRuleSet` | SQL injection patterns against the API |
| 3 | `AWSManagedRulesAmazonIpReputationList` | Known bad actors / bot IPs |

## How traffic flows

```text
Internet
   ↓
WAF (REGIONAL, attached to the ALB)
   ↓
ALB :443
   ↓
Target group → EC2
```

Because the ACL is **regional** and attached to the ALB, every request is
inspected before it reaches the load balancer. Blocked requests never touch
the application.

## Important notes

- The default action is `allow` and only AWS managed rules are enabled; this
  keeps false positives low. To block *all* requests during an incident, change
  `default_action` to `block`.
- WAF sampling + metrics are enabled per rule (`sampled_requests_enabled`,
  `cloudwatch_metrics_enabled`) so you can see what was blocked in CloudWatch.
- Custom rules can be added later (rate limiting, geo restrictions, allow-lists).

## Verification

```bash
aws wafv2 list-web-acls --scope REGIONAL --region eu-west-1
aws wafv2 get-web-acl --name <name> --id <id> --scope REGIONAL --region eu-west-1
```

Send a test attack payload through the ALB:

```bash
curl -s "https://<ALB_DNS>/?id=1'%20OR%20'1'='1" -o /dev/null -w '%{http_code}\n'
```

Expected: `403` when the SQLi rule blocks it. Then check the WAF metrics in
CloudWatch (`<project>-<env>-waf` metric names).

## Cost

WAF has a low monthly cost per web ACL plus per rule group. The three managed
rule groups here are the recommended baseline.
