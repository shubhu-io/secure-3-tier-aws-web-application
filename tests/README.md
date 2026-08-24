# Testing

This project has a layered test strategy. Each layer answers a different
question and each runs at a different point in the lifecycle.

## 1. Unit & API tests — `application/backend/test/`

- **Runner:** Node's built-in test runner (`node --test`).
- **Approach:** the Express app is a factory (`createApp(deps)`) so tests
  inject a **fake database** — no PostgreSQL required in CI.
- **Coverage:** health endpoint (db up/down/missing), readiness probe, 404
  handling, register (validation, duplicates, normalization), login (success,
  wrong password), items (auth required, tampered tokens, CRUD).

```bash
cd application/backend
npm ci
npm test
```

## 2. Frontend build test

Proves the React app compiles for production.

```bash
cd application/frontend
npm ci
npm run build
```

## 3. Image security tests — in CI (Trivy)

Every image is scanned by [Trivy](https://trivy.dev) with `exit-code: 1`,
`severity: CRITICAL,HIGH`. The pipeline **fails** if a critical/high CVE is
found. `npm audit` also runs against the backend dependencies.

## 4. Infrastructure tests — `tests/infrastructure/`

```bash
bash tests/infrastructure/terraform-validate.sh    # fmt + validate
bash tests/infrastructure/tfplan-check.sh          # plan contains key resources
bash tests/infrastructure/stack-validate.sh        # manifest scripts: stack-validate/info + render-manifests
bash tests/infrastructure/kubernetes-validate.sh   # render + kustomize + dry-run the k8s manifests
```

`tfplan-check.sh` greps the plan JSON to prove the VPC, subnets, NAT, SGs,
ALB, ASG, RDS, ECR, WAF, alarms, flow logs and CloudTrail are all created.
`stack-validate.sh` runs the manifest-driven scripts without a cluster: the
repo `stack.json` passes `stack-validate.sh`, every `stack-info.sh` subcommand
returns the expected value, `render-manifests.sh` produces the right shapes
(2 services × Deployment/Service/HPA/PDB, exactly one LoadBalancer, `fsGroup`
on the internal service only), and malformed manifests are rejected. Needs `jq`
on PATH (skips if missing).
`kubernetes-validate.sh` needs `kubectl` on PATH (skips if missing); it renders
the per-service Deployment/Service/HPA/PDB from `stack.json`, asserts every
manifest service has matching rendered kinds + a non-root `securityContext`,
and dry-runs the result. Because it reads `stack.json`, new services are
covered automatically.

## 5. Application integration tests — `tests/application/integration.sh`

Exercises the real API end-to-end through HTTP (locally through Nginx, or
against the ALB): register → login → wrong password → create → list →
unauthorized → delete. Requires a running stack (local compose or deployed).

## 6. Security tests — `tests/security/security-tests.sh`

Verifies the security model is actually enforced on a **deployed** stack:

- RDS is not publicly accessible and is encrypted
- WAF web ACL exists
- No SSH open to the world on the app SG
- No PostgreSQL open to the world on the DB SG
- Health endpoint responds
- HTTP → HTTPS redirect (when a domain is configured)
- WAF blocks a SQL injection payload (`403`)

## 7. Failure tests — manual runbooks

| Scenario | How to test | Expected behaviour |
| -------- | ----------- | ------------------ |
| EC2 instance dies | `aws ec2 terminate-instances --instance-ids <id>` | ALB marks it unhealthy, ASG launches a replacement, traffic restored |
| Application stops | `docker stop <frontend-container>` on an instance | Health check fails → ASG replaces the instance |
| Bad traffic | Send SQLi payload via curl | WAF returns 403 |
| Full outage | Simulate DB failure / AZ loss | RDS multi-AZ failover (prod), ASG keeps app running |

Walkthroughs: [`docs/operations/troubleshooting.md`](../docs/operations/troubleshooting.md)
and the runbooks in [`docs/runbooks/`](../docs/runbooks/).

## Running everything

```bash
# local (no AWS)
docker compose up -d --build     # in docker/
bash tests/integration/e2e.sh

# against a deployed environment
bash tests/security/security-tests.sh eu-west-1 secure-ntier dev https://app.example.com
bash tests/application/integration.sh https://app.example.com
```
