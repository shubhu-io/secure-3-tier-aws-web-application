# Prerequisites

Everything you need installed before touching this project. Run
`bash scripts/setup.sh` to check your machine.

## Required tools

| Tool | Minimum | Why | Install |
| ---- | ------- | --- | ------- |
| Git | 2.x | Version control | https://git-scm.com |
| Terraform | 1.5 | Infrastructure as Code | https://developer.hashicorp.com/terraform/install |
| AWS CLI v2 | 2.x | AWS API access | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| Docker | 20+ with Compose v2 | Local app stack + image builds | https://docs.docker.com/engine/install/ |
| Node.js | 20+ | Build/run the app locally | https://nodejs.org |
| curl | — | Health checks | Preinstalled on most systems |

## Optional but useful

- `jq` — parse JSON in scripts.
- `mermaid-cli` or the mermaid.live website — render the `.mmd` diagrams.
- A GitHub account + repository.

## Verify the install

```bash
git --version
terraform version
aws --version
docker --version
docker compose version
node --version
```

Expected output example:

```text
git version 2.44.0
Terraform v1.9.8
aws-cli/2.17.9
Docker version 27.1.1
Docker Compose version v2.29.1
v20.15.0
```

## If a check fails

### `terraform` not found

Download the zip for your OS, unzip to a folder in your PATH, verify:

```bash
terraform version
```

### `aws` not found

Install the v2 bundle (see link above), then:

```bash
aws --version
aws configure
```

### `docker` not found / daemon not running

Install Docker Desktop (Windows/macOS) or the Docker engine (Linux). On
Windows the daemon must be running — start Docker Desktop and wait for the
whale to show "Engine running".

### `node` too old

Install Node 20 LTS via the installer or a version manager (`nvm`).

## AWS credentials

The AWS CLI needs credentials for anything against your account:

```bash
aws configure
```

You will enter: access key, secret key, default region, output format.

> ⚠️ Never commit `~/.aws/credentials` or paste keys into the repository.
> Use an **IAM user** (not root) — see [aws-setup.md](./aws-setup.md).

## Next step

[Prepare your AWS account](./aws-setup.md).
