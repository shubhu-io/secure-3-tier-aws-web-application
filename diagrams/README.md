# Diagrams

All diagrams are authored as **[Mermaid](https://mermaid.js.org) sources** so they
are version-controllable, reviewable in pull requests, and renderable anywhere.
No fake screenshots — every diagram is derived from the actual Terraform,
pipeline, and application code in this repository.

Pre-rendered **PNG copies live in [`rendered/`](./rendered)** and are embedded
in the main [`README.md`](../README.md), so the diagrams display on GitHub
without any rendering step.

## Diagram index

| File | What it shows |
| ---- | ------------- |
| [`architecture.mmd`](./architecture.mmd) | End-to-end platform: user → Route 53 → WAF → ALB → EC2/ASG → RDS, plus supporting services (NAT, Secrets Manager, CloudWatch) |
| [`network.mmd`](./network.mmd) | VPC + subnet layout with CIDR blocks, route tables, and NACLs per tier |
| [`security.mmd`](./security.mmd) | Defense-in-depth: WAF → ALB SG → App SG → DB SG, encryption, IAM, secrets, auditing |
| [`cicd.mmd`](./cicd.mmd) | CI/CD pipeline (manifest-driven): commit → validate → test/scan → build → ECR → deploy EC2/EKS → smoke test; failure blocks the release |
| [`stack.mmd`](./stack.mmd) | `stack.json` manifest: how one source of truth drives CI/CD, Terraform, and Kubernetes, and how a new service is added |
| [`request-flow.mmd`](./request-flow.mmd) | Sequence diagram of one browser request through every layer |
| [`deployment-flow.mmd`](./deployment-flow.mmd) | Deployment lifecycle including a rollback branch |
| [`failure-flow.mmd`](./failure-flow.mmd) | Sequence diagram of EC2 failure and self-healing by the ASG |
| [`disaster-recovery.mmd`](./disaster-recovery.mmd) | RPO / RTO targets and how data + infrastructure are recovered |
| [`kubernetes.mmd`](./kubernetes.mmd) | The EKS deployment path: NLB → frontend → backend → RDS, plus HPA/PDB/secrets |

## How to render

### Option A — Mermaid Live Editor (no install)

1. Open https://mermaid.live
2. Paste the content of the `.mmd` file
3. Export as PNG / SVG / click "[ ] code"

### Option B — Mermaid CLI (local, reproducible)

```bash
# needs Node.js + npx
npx -y @mermaid-js/mermaid-cli -i diagrams/architecture.mmd -o artifacts/architecture.png -b white
```

For a batch render of all diagrams:

```bash
mkdir -p artifacts
for f in diagrams/*.mmd; do
  npx -y @mermaid-js/mermaid-cli -i "$f" -o "artifacts/$(basename "${f%.mmd}").png" -b white
done
```

> Note: the first `npx` run downloads the tool and Chromium, which takes a minute.

### Option C — GitHub / VS Code

- GitHub renders `mermaid` blocks directly in Markdown (the sources are also
  embedded in the docs under `docs/architecture/`).
- VS Code: install the "Mermaid Preview" or "Markdown Preview Mermaid Support"
  extension and open the `.mmd` file.

## Keeping diagrams accurate

- Diagrams must always match the Terraform resources in [`terraform/cloud/<cloud>/modules/`](../terraform).
- If you change a CIDR, subnet tier, port, or pipeline stage, update the
  corresponding `.mmd` file in the same change so docs never drift from code.