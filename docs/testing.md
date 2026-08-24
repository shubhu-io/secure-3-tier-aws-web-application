# Testing Strategy

This document describes **every** test in the project: what it verifies, which
layer of the stack it protects, where it runs, and how to run it yourself.

Testing is layered so failures are found as cheaply and as early as possible:

```text
Unit tests         (fast, milliseconds)      run on every push
API tests          (fast, ~1s)               run on every push
Build + scan       (Docker + Trivy + npm)    run on every push
Infrastructure     (validate + plan checks)  run on every push
Integration/E2E    (real HTTP flow)          run on demand / after deploy
Security tests     (environment assertions)  run on demand / before release gates
Failure tests      (chaos: kill/stop/attack) run manually on dev
```

---

## 1. Test pyramid view of this repo

```text
                 /  Failure tests  \      ← rare, expensive, high value
               /   Security tests    \
             /     Integration / E2E    \
           /       Infrastructure tests   \
         /         Docker build + scan      \
       /           API tests                  \
     /___         Unit tests                     ___\
```

| Layer | Where | Runs |
| ----- | ----- | ---- |
| Unit / API | `application/backend/test/*.test.js` | CI (`ci.yml`) + locally |
| Frontend build | `application/frontend` | CI `build-frontend` job |
| Docker build | `docker/**` | CI `docker-build-and-scan` |
| Container scan | Trivy | CI, against every image |
| Dependency audit | `npm audit` | CI |
| Infrastructure | `tests/infrastructure/*` | CI (`terraform fmt` + `validate`); `tfplan-check.sh` locally |
| Integration | `tests/application/integration.sh` | demands a running app |
| End-to-end | `tests/integration/e2e.sh` | against an AWS deployment |
| Security | `tests/security/security-tests.sh` | on demand / release gate |
| Failure (chaos) | manual (see phase 26) | on dev, documented in runbooks |

---

## 2. Application tests

### 2.1 Backend unit + API tests

```bash
cd application/backend
npm ci
npm test
```

What runs (see `test/auth.test.js`, `health.test.js`, `items.test.js`):

- **Health**: `/health` returns `200` with `{status:"ok"}`; `/health/ready`
  reports DB connectivity against a fake DB.
- **Auth**: register returns a token; duplicate email rejected; wrong password
  rejected; JWT guards protected routes.
- **Items**: CRUD works with a valid token; unauthorized requests rejected.

The tests inject a fake database via the app factory
(`src/app.js` `deps.db`), so no real database is needed for unit tests.

### 2.2 Frontend build

```bash
cd application/frontend
npm ci
npm run build
```

Proves the SPA compiles; catches broken imports and syntax errors before a
container is built.

### 2.3 Integration tests (HTTP against a running stack)

```bash
# with docker compose up running (see phase 12)
bash tests/application/integration.sh --base-url http://localhost
```

Verifies the real endpoints over HTTP: `/health`, register → login → create
item → list items.

### 2.4 End-to-end (against AWS)

```bash
bash tests/integration/e2e.sh --base-url https://app.example.com
```

The full user journey against the deployed platform. Used after a deploy.

---

## 3. Infrastructure tests

### 3.1 Terraform validate

```bash
bash tests/infrastructure/terraform-validate.sh
# equivalent: cd terraform && terraform validate
```

### 3.1.1 Multi-cloud validation

The Terraform root is now a dispatcher that instantiates exactly one cloud
implementation (`-var="cloud=aws|azure|gcp"`), so static validation runs
**per cloud directory** — each of `terraform/cloud/aws`, `terraform/cloud/azure`,
and `terraform/cloud/gcp` is its own self-contained Terraform configuration
with its own providers and modules:

```bash
for d in aws azure gcp; do
  (cd "terraform/cloud/$d" && terraform init -backend=false && terraform validate)
done
```

What this proves: the infrastructure checks validate the *selected* cloud's
module, and every cloud module must satisfy the same contract — same inputs
(from the shared `stack.json` + shared variables) and the same normalized
outputs (`app_url`, `lb_dns_name`, `db_host`, `db_secret_ref`, `registry_url`,
…). A port that breaks the output contract fails validation just like a broken
AWS change would.

> The Azure/GCP modules are reference implementations pending live validation;
> `validate` proves they compile against the contract, not that they have been
> applied against a live subscription/project.

### 3.2 Plan sanity check

```bash
bash tests/infrastructure/tfplan-check.sh
```

Parses `terraform plan` output and asserts the platform's shape:

```text
subnets  == 6        (2 public + 2 app + 2 db)
sgs      == 3        (alb, app, db)
alb      == 1
asg      == 1        + launch template
rds      == 1
sql/ecr  repos == 2
nacls    == 3        (public, app, db)
waf      == 1
```

Fails loudly if the plan drifts from the expected architecture — a built-in
test of the "error-prevention" rule that a resource rename doesn't silently
change the topology.

### 3.3 `terraform fmt` check (in CI)

```bash
terraform fmt -check -recursive
```

Enforces consistent style; a style change isn't a semantic bug, but reviewable
code keeps diffs small and safe.

### 3.4 Manifest-driven scripts (no cluster needed)

```bash
bash tests/infrastructure/stack-validate.sh
```

Needs `jq` on PATH (skips gracefully if missing). Asserts the manifest-driven
scripts agree with `stack.json`:

- `cicd/scripts/stack-validate.sh` accepts the repo `stack.json` (and rejects
  malformed manifests: two public services, a missing `source_dir`)
- `cicd/scripts/stack-info.sh` returns the expected values for `project`,
  `list`, `count`, `public-service`, `db-engine`, `db-port`, `db-version`,
  `field`, and `ci-steps`
- `kubernetes/scripts/render-manifests.sh` produces one Deployment/Service/HPA/
  PDB per service (8 resources), exactly one `LoadBalancer` (the public
  service), `fsGroup` only on the internal service, HPA `maxReplicas`/CPU
  target and PDB `minAvailable` as expected

Because everything reads `stack.json`, adding a service extends what these
checks cover automatically.

### 3.5 Kubernetes manifests

```bash
bash tests/infrastructure/kubernetes-validate.sh
```

Validates the `kubernetes/` deployment with `kubectl` + `jq`:

- `kubectl kustomize kubernetes/` — the kustomization (namespace + configmap)
  builds cleanly
- `kubectl kustomize kubernetes/ | kubectl apply --dry-run=client -f -` — the
  static support resources are valid API objects (no cluster needed)
- `kubernetes/scripts/render-manifests.sh` — renders per-service
  Deployment/Service/HPA/PDB from `stack.json`; the script asserts **all
  services** in the manifest have matching rendered kinds and a valid
  `securityContext` (non-root everywhere, `fsGroup` on internal services)
- when a cluster is reachable (`kubectl cluster-info` succeeds) it also runs
  `kubectl apply --dry-run=client -f -` over the rendered output

Requires `kubectl` on PATH; the script skips gracefully if it's missing. It
reads `stack.json` from the repo root, so the check automatically covers any
service you add to the manifest.

When a real cluster is available you can also run the deployment assertions
from `docs/architecture/kubernetes.md` (`kubectl get all -n secure-ntier`,
`curl /health` on the NLB endpoint).

---

## 4. Container / dependency security scans

Runs in CI (`ci.yml` → `docker-build-and-scan` and `deploy.yml`):

| Check | Command equivalent | Gate |
| ----- | ------------------ | ---- |
| Dev dependency audit | `npm audit --audit-level=high` | fails on HIGH/CRITICAL advisories |
| Backend image scan | `trivy image secure-ntier-backend:ci --severity CRITICAL,HIGH --exit-code 1` | fails on CRITICAL/HIGH |

Trivy scans run against the **exact image** that will be deployed — a CVE in a
base layer is caught before push, not after.

```bash
# locally, before pushing anything
docker build -f docker/backend/Dockerfile -t secure-ntier-backend:tmp .
docker run --rm aquasec/trivy:latest image --exit-code 1 \
  --severity CRITICAL,HIGH secure-ntier-backend:tmp
```

### 4.1 Infrastructure-as-Code security scans (tfsec + checkov)

Runs in CI (`ci.yml` → `iac-security-scan` job and `Jenkinsfile-ci`):

| Check | Command equivalent | Gate |
| ----- | ------------------ | ---- |
| Terraform lint | `tfsec terraform --config-file .tfsec` | fails on CRITICAL/HIGH |
| Policy-as-code | `checkov -d terraform --config-file .checkov.yml` | fails on HIGH+ |

Both config files live at the repo root and are shared with the Jenkins
pipeline (run in the toolchain containers). The configs document every
intentional exclusion (e.g. the opt-in Jenkins SG defaults) rather than
silently skipping checks.

```bash
# locally
docker run --rm -v "$PWD:/workspace" -w /workspace aquasec/tfsec:latest terraform
docker run --rm -v "$PWD:/workspace" -w /workspace bridgecrew/checkov:latest -d terraform
```

### 4.2 Static analysis (SonarQube, optional)

`sonar-project.properties` at the repo root configures `sonar-scanner` for the
backend + frontend sources and the backend tests. Runs in Jenkins when a
`SonarQube` server credential is configured (skipped otherwise). It is advisory
by default — set `sonar.qualitygate.wait=true` to make it a hard gate.

---

## 5. Security tests

```bash
cd tests/security
bash security-tests.sh --region eu-west-1 --alb-url http://<ALB_DNS>
```

Assertions (see `tests/security/security-tests.sh` for full list):

| Check | What it proves |
| ----- | -------------- |
| RDS public | `PubliclyAccessible == false` |
| `PublicIp` on app instances | none |
| ALB SG ports | only 80/443 exposed to `0.0.0.0/0` |
| DB SG | 5432 allowed only from the app SG |
| HTTPS | `:443` answers (when a domain is configured) |
| WAF association | web ACL attached to the ALB |
| Empty SSH/3389 | no public SSH anywhere |
| WAF behavior | SQLi and XSS payloads return `403` |
| Secret scan | git-tracked files contain no `password`/`secret`/keys |
| IAM | policy documents grant only required actions |

> Note: "fails to connect to the DB from the internet" is *expected*. The test
> asserts the *configuration*, not a successful connection. The strongest form
> is a port-scan/timeout check against the private CIDRs.

---

## 6. Failure / chaos tests

These are manual tests on **dev only**, documented in `docs/runbooks/`:

| Test | How | Expected |
| ---- | --- | -------- |
| Instance dies | `aws ec2 terminate-instances --instance-ids <id>` | ASG launches a replacement; traffic unaffected |
| Container dies | `docker compose -f /opt/app/docker-compose.yml stop backend` on an instance | health check fails; ASG/recovery brings it back |
| Bad traffic | SQLi / XSS payload to the ALB | `403` from WAF |
| ASG refresh | pushed `main` triggers instance refresh | rolling swap keeps 50%+ healthy |
| DB unreachable | stop RDS briefly (dev) | alarms fire; app `/health` shows `db: disconnected`; no crash-loop |

---

## 7. How tests gate CI/CD

```text
push (feature/*, develop) ────── ci.yml / Jenkinsfile-ci
   │  stack-validate → stack-ci per service (tests + audit + build + trivy)
   │  npm audit ── terraform fmt + validate ── tfsec ── checkov
   ▼  any fail → PR blocked; no image pushed

local / on-demand ────────────── tfplan-check.sh (asserts topology)
                                 kubernetes-validate.sh (render + dry-run)

merge to main / push main ────── deploy.yml / Jenkinsfile
   │  tests again → stack-push (ECR) → per-service SSM pointer
   │  → instance refresh → smoke test (+ optional EKS deploy + NLB smoke)
   ▼  scan fail or smoke fail → ALB still on previous image (rollback in runbook)
```

Guarding corrupts nothing: a bad image is never pushed; a bad pointer is never
written; a black smoke test leaves the previous deployment serving traffic.

---

## 8. Test maintenance rules

1. **Update tests when the architecture changes.** `tfplan-check.sh` and the
   security tests encode expectations; change them in the same PR as the change.
2. **Never weaken a gate to make it pass** — fix the product.
3. **Run the full suite before merging** (`npm test`, terraform checks, and —
   where meaningful — `security-tests.sh`).
4. Keep tests **fast** so developers actually run them.

See `tests/README.md` for file-by-file instructions.