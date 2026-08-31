# Screenshots

> **Policy:** this project never ships fabricated screenshots. Images in the
> README and docs are either (a) Mermaid diagrams rendered from source
> (`diagrams/`), or (b) **your** captures following the instructions below.
> Nothing in this folder is auto-generated to "look like" an AWS console.

> **Image ideas:** full categorized list with filenames lives in [`screenshots/IMAGE_IDEAS.md`](./IMAGE_IDEAS.md) — generate per that guide, drop files in `screenshots/<folder>/NN-...png`, and I will wire them into README + step files (*jaha jarurat hai waha add kar dunga*).

## Folder layout

```
screenshots/
├── IMAGE_IDEAS.md   # master list (terraform / jenkins / cicd / deployment / k8s / monitoring)
├── terraform/       # T01–T08 terraform steps
├── jenkins/         # J01–J09 Jenkins steps
├── cicd/            # C01–C05 GitHub Actions
├── deployment/      # D01–D08 app verification
├── kubernetes/      # K01–K04 EKS/AKS/GKE
├── monitoring/      # M01–M03 CloudWatch etc.
└── *.png            # legacy flat captures (deprecated, use subfolders)
```

Drop captured screenshots here (`.png`, < 500 KB each) and link them from docs
with relative paths. Suggested capture checklist for when you deploy the
platform yourself (legacy flat list — prefer subfolder READMEs):

## Suggested captures (AWS Console → navigate → screenshot)

| # | What to capture | Path in the console | Why |
| - | --------------- | ------------------- | --- |
| 1 | VPC map (subnets per tier) | VPC → Your VPCs → select VPC → Resource map | proves the 3-tier layout |
| 2 | Route tables | VPC → Route tables → each table | public→IGW, app→NAT, db→none |
| 3 | Security groups | EC2 → Security groups → ALB/App/DB | layered SG chain |
| 4 | Load balancer health | EC2 → Load balancers → select ALB → Target groups → Targets | 2× healthy targets |
| 5 | Auto Scaling group | EC2 → Auto Scaling groups → select → Activity | instance replacement after failure |
| 6 | RDS instance | RDS → Databases → secure-ntier-* → Configuration | private, encrypted, multi-AZ off (dev) |
| 7 | Secrets Manager secret | Secrets Manager → secure-ntier-*-db-credentials | credentials not in code |
| 8 | CloudWatch alarms | CloudWatch → Alarms → all alarms | 5 alarms listed |
| 9 | CloudWatch dashboard | CloudWatch → Dashboards → secure-ntier-* | monitoring overview |
| 10 | WAF web ACL | WAF → Web ACLs → secure-ntier-* → Rules | managed rule groups |
| 11 | Pipeline green run | GitHub → Actions → deploy workflow → success | CI/CD proof |
| 12 | App login screen | browser → `http://<ALB_DNS>` (or HTTPS URL) | application running |

## How to capture cleanly

- Use your OS screenshot tool or browser devtools (full-page capture).
- Keep **personal data out** — redact emails/IPs if present.
- Save as `NN-description.png` (e.g. `01-vpc-resource-map.png`).

## Where screenshots plug into docs

- `README.md` → **Architecture** section (optional hero image).
- `docs/architecture/*.md` → component-specific captures.
- `docs/deployment/*.md` → console walkthroughs ("Expected result" per section
  in the master guide's console-guide format).

> Never claim a diagram or image is a real AWS console screenshot — mark
> renders as "Diagram: …" and screenshots as "Screenshot: …".