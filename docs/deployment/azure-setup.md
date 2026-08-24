# Azure Subscription Preparation

> ⚠️ **COST WARNING** — Everything on this page is free or near-free, but the
> **deployment** itself creates billable resources (VMSS, Application Gateway,
> NAT Gateway, PostgreSQL Flexible Server, ACR, Azure Monitor). Read
> [`docs/cost-guide.md`](../cost-guide.md) before you `terraform apply`, and
> run `terraform destroy` when done.

> **Honesty note:** the Azure module (`terraform/cloud/azure/`) is a port of
> the AWS reference implementation and is **pending live validation** — expect
> rough edges, and verify costs in the Azure pricing calculator for your
> region first.

## 1. Install the CLI and sign in

```bash
az login
az account list --output table
az account set --subscription "<YOUR-SUBSCRIPTION-ID>"
```

Verify:

```bash
az account show --query "{name:name, id:id}"
```

## 2. Register the resource providers (one-time)

Some providers are not registered by default on new subscriptions:

```bash
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
```

## 3. Prepare the Terraform state backend

By default each cloud's `backend.hcl` keeps state in an **S3 bucket** (a
cloud-agnostic choice shared across clouds — see
[`terraform/cloud/azure/backend.hcl`](../../terraform/cloud/azure/backend.hcl)).
If you prefer a fully-Azure state store, swap the backend block to `azurerm`
and create:

```bash
az group create --name rg-terraform-state --location westeurope

az storage account create --name <UNIQUE-STATE-STORAGE> \
  --resource-group rg-terraform-state --sku Standard_LRS --encryption-services blob

az storage container create --name tfstate \
  --account-name <UNIQUE-STATE-STORAGE>
```

Then initialize with `-backend-config="cloud/azure/backend.hcl"` as documented
in [`terraform.md`](./terraform.md).

## 4. Create the CI/CD service principal

GitHub Actions (or Jenkins) needs a non-interactive identity:

```bash
az ad sp create-for-rbac \
  --name github-actions-cicd \
  --scopes /subscriptions/<SUBSCRIPTION-ID> \
  --role Contributor
```

The command prints `appId`, `password`, `tenant`. Store them as repository
secrets (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`). Prefer
**OIDC/federated credentials** over the client secret where possible
(`az ad app federated-credential create`) — no long-lived secret then exists.

**Least privilege:** `Contributor` at a subscription scope is only acceptable
for this learning project. After the first `terraform apply`, replace it with
the exact permissions printed by Terraform's normalized **`cicd_policy_json`
output** (registry push, scale-set update, etc.) — that document is the source
of truth for what CI actually needs.

If you provision AKS (`azure_enable_aks = true`), pass the principal's object
ID as `azure_aks_ci_principal_id` so CI gets cluster access.

## 5. (Optional) Domain for HTTPS

Application Gateway can terminate TLS with a certificate from Key Vault. Point
your domain's DNS record at the Application Gateway public IP (the Terraform
output `lb_dns_name` / `app_url`) once deployed.

## Next step

[Deploy infrastructure with Terraform](./terraform.md).
