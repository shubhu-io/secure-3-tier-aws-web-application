# Terraform — Secure n-tier Azure Infrastructure

Azure implementation of the secure n-tier platform: Virtual Network, NSGs,
Application Gateway + WAF, VM Scale Set, Azure Container Registry (ACR),
PostgreSQL Flexible Server + Key Vault, Monitor alerts + dashboard, optional
AKS and Jenkins. Everything is driven by the repo's `stack.json` manifest and
the environment tfvars, mirroring the AWS module layout.

## Layout

```
terraform/cloud/azure/
├── provider.tf     provider config (azurerm with features{})
├── versions.tf     terraform + provider version pins (azurerm ~> 3.110, random ~> 3.6)
├── variables.tf    root variables (all from the multi-cloud dispatcher)
├── locals.tf       derived values (AZs, stack.json decode, db_port)
├── main.tf         wires every module + CI/CD RBAC assignments
├── outputs.tf      normalised outputs consumed by terraform/outputs.tf
├── modules/
│   ├── vpc/        VNet, subnets, NAT Gateway(s), route tables
│   ├── security/   public / app / db NSGs (layered, least privilege)
│   ├── registry/   ACR (admin disabled + RBAC)
│   ├── alb/        Application Gateway (WAF_v2) + TLS from Key Vault + WAF policy
│   ├── compute/    user-assigned identity, VMSS, cloud-init, autoscale
│   ├── database/   PostgreSQL Flexible Server (private) + Key Vault secret
│   ├── monitoring/ action group + metric alerts + dashboard
│   ├── aks/        optional AKS cluster + node pool
│   └── jenkins/    optional self-hosted Jenkins controller on a VM
└── README.md
```

## Azure concepts ↔ AWS mapping

| AWS | Azure |
| --- | --- |
| VPC | Virtual Network |
| Subnet + NACL | Subnet + NSG |
| Internet Gateway + NAT GW | NAT Gateway (public IP) |
| EC2 Launch Template + ASG | VM Scale Set + autoscale setting |
| ECR | Azure Container Registry (ACR) |
| RDS + Secrets Manager | PostgreSQL Flexible Server + Key Vault |
| ALB + WAFv2 | Application Gateway (WAF_v2) + WAF policy |
| SNS + CloudWatch alarms | Monitor action group + metric alerts |
| CloudWatch dashboard | Azure dashboard |
| EKS | AKS |
| IAM roles / instance profile | Managed identities + RBAC role assignments |

## Security model (secure-by-default)

- App and DB instances live in private subnets; only the Application Gateway
  is publicly reachable (public IP on the gateway, not on the VMs).
- **Layered NSGs:** `public` (App Gateway: 80/443 + Azure Load Balancer health
  probes) → `app` (only from the App Gateway subnet) → `db` (only from the app
  subnet on 5432, no internet route). The DB subnet has no route to the
  internet.
- The PostgreSQL Flexible Server has `public_network_access_enabled = false`
  and is injected into the delegated DB subnet with a private DNS zone.
- **No secrets on disk.** The VMSS uses a user-assigned managed identity to
  pull images from ACR (`AcrPull`) and read DB credentials from Key Vault
  (`Key Vault Secrets User`). The cloud-init script logs in with the identity
  at boot — no embedded credentials.
- ACR has admin disabled; access is RBAC-only.
- Application Gateway is protected by a WAF policy (OWASP 3.2, Prevention mode)
  and terminates TLS with a certificate stored in Key Vault (self-signed by
  default; replace with a CA cert / App Service cert for production).
- IMDS is available to the VMSS but no SSH ingress is opened; use Azure
  Bastion / run-command for admin access.

## CI/CD permissions

`cicd_policy_json` (root output) describes, as a JSON document, the Azure RBAC
role assignments the pipeline principal needs:

- `Contributor` on the resource group
- `AcrPush` and `AcrPull` on the ACR
- `Monitoring Contributor` on the resource group

When `aks_ci_principal_id` (Azure) is supplied, these assignments are created
automatically via `azurerm_role_assignment`.

## Notes / deviations from AWS

- **App Gateway subnet NSG:** Azure Application Gateway co-exists with an NSG
  on its subnet as long as the required health-probe ports (65200-65535 from
  `AzureLoadBalancer`) and 80/443 rules are present; these are configured in
  the security module.
- **Backend pool population:** the Application Gateway backend pool is populated
  from the VMSS network interface private IPs via a `data` source. This is the
  standard VMSS+AppGW pattern; it resolves once the VMSS exists at apply time.
- **TLS certificate:** a self-signed certificate is generated in a dedicated
  Key Vault for the gateway. For production, supply a CA-issued certificate
  (or reference an existing Key Vault secret) instead.
- **SSH / password auth:** the VMSS and Jenkins VM use a strong random
  password (`disable_password_authentication = false`) because no SSH public
  key is wired through the multi-cloud variables. For production, disable
  password auth and use Azure AD login or an SSH key.

## Validate

```bash
terraform fmt -recursive terraform/cloud/azure
terraform init -backend=false -input=false   # no Azure creds needed
terraform validate
```

## Plan / Apply

```bash
terraform init
terraform plan  -var="cloud=azure" -var-file="environments/dev/terraform.tfvars"
terraform apply -var="cloud=azure" -var-file="environments/dev/terraform.tfvars"
```

Requires `AZURE_CLIENT_ID` / `AZURE_SUBSCRIPTION_ID` / `AZURE_TENANT_ID` /
`AZURE_CLIENT_SECRET` (or `az login`) and the `Contributor` role on the
subscription (the deployer object id is used for the Key Vault cert).
