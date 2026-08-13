# Contributing

Thanks for contributing to the n-tier cloud platform project.

## Ground rules

1. **Never commit secrets.** Any `.env`, `*.pem`, `*.tfvars` (non-example), or
   credential-like content will be rejected.
2. **Keep every file consistent.** If you rename a Terraform resource, update
   every reference. If you add a variable, define it. If you add an output,
   create it. The repository is reviewed as a whole.
3. **No pseudo-code.** Claims like "health checks configured" require the
   actual configuration.
4. **Follow the structure.** New modules/docs go in the matching folder.

## Workflow

```text
main
├── develop
│   ├── feature/*
│   ├── bugfix/*
│   └── hotfix/*
```

1. Branch from `develop`: `git checkout develop && git switch -c feature/<name>`
2. Make small, focused commits (see conventions below).
3. Push and open a Pull Request against `develop`.
4. CI must pass: unit tests, Docker build, Trivy scan.
5. A reviewer approves; the branch is merged.

## Commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add WAF association to ALB module
fix: correct security group ingress for app tier
docs: explain subnet CIDR calculation
refactor: extract ecr-login helper script
test: add ALB health check test
chore: bump terraform provider pins
security: restrict DB security group to app CIDR only
```

## Validation before opening a PR

```bash
cd terraform
terraform fmt -recursive
terraform validate
terraform plan -out plan.tfplan    # review the diff
```

```bash
cd application/backend
npm ci && npm test
```

```bash
cd application/frontend
npm ci && npm run build
```

```bash
# local stack (no AWS required)
cd docker
docker compose up --build
curl -s http://localhost/health
```

## Documentation

Update the relevant docs when you change behaviour:

- `docs/architecture/*`  — architecture decisions and diagrams
- `docs/deployment/*`    — setup and run steps
- `docs/operations/*`    — monitoring, backup, scaling
- `docs/runbooks/*`      — incident procedures
- `docs/adr/*`           — architecture decision records
