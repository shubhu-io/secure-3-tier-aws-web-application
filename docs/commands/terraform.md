# Terraform / Infrastructure as Code

Reference commands for Terraform. This project uses Terraform for multi-cloud infrastructure provisioning (AWS, Azure, GCP).

## Installation

```bash
# macOS
brew install terraform

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common
# Add HashiCorp repository
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Windows: Download from developer.hashicorp.com

# Or using SDKMAN
sdk install terraform

# Verify
terraform --version
```

## Version Check

```bash
terraform --version
```

## Command Reference

```bash
# Initialize working directory
terraform init

# Format configuration files (in this project)
terraform fmt -recursive

# Validate configuration
terraform validate

# Review changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show state
terraform show

# Output values
terraform output

# Import existing resource
terraform import

# Taint resource (mark for replacement)
terraform taint

# Refresh state
terraform refresh

# Force resource to be recreated
terraform force-replace
```

## Init

```bash
# Initialize working directory (required before other commands)
terraform init

# With backend configuration (this project uses remote state)
terraform init -backend="s3" \
  -backend-config="bucket=my-tf-state-bucket" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=ap-south-1"

# Initialize without backend (local state)
terraform init -backend=false

# Install plugins/handlers
terraform init -upgrade

# This project's Terraform structure:
# - terraform/ root module dispatches via -var="cloud=aws|azure|gcp"
# - terraform/cloud/aws/ modules for reference implementation
# - terraform/cloud/azure/ and terraform/cloud/gcp/ for multi-cloud
```

## Validate

```bash
# Validate configuration files
terraform validate

# Fix formatting issues
terraform fmt -check -recursive  # Check only (exit code 1 if changes needed)
terraform fmt -recursive         # Auto-fix formatting

# This project runs these in CI (ci.yml):
# - terraform fmt -check -recursive
# - terraform validate
```

## Plan

```bash
# Create an execution plan
terraform plan

# Plan with specific variables
terraform plan -var="cloud=aws"
terraform plan -var="project_name=secure-ntier"
terraform plan -var-file="environments/dev/terraform.tfvars"

# Plan with out file (save plan for later apply)
terraform plan -out=plan.tfplan

# Show changes in plan
terraform plan -detailed-exitcode  # Exit code 2 = changes, 3 = no changes

# Plan with refresh
terraform plan -refresh-only     # Only refresh state, don't evaluate changes

# This project's typical usage:
# terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
```

## Apply

```bash
# Apply a previously saved plan
terraform apply plan.tfplan

# Apply interactively (approves each change)
terraform apply

# Apply automatically (non-interactive)
terraform apply -auto-approve

# Apply with variables
terraform apply -var="cloud=aws" -auto-approve

# Apply with plan file
terraform apply plan.tfplan

# This project's typical usage:
# terraform apply -var="cloud=aws" -var-file="environments/dev/terraform.tfvars" -auto-approve
```

## Destroy

```bash
# Destroy all infrastructure
terraform destroy

# Destroy with auto-approval (dangerous!)
terraform destroy -auto-approve

# Destroy with specific variables
terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"

# This project recommends reviewing plan before destroy:
# 1. terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
# 2. Review output
# 3. terraform destroy -auto-approve
```

## Output

```bash
# Show output values
terraform output

# Show specific output
terraform output project_name

# Show all output as JSON
terraform output -json

# This project's Terraform outputs (per cloud):
# - alb_dns_name
# - app_security_group_id
# - rds_endpoint
# - rds_password
# - ec2_instance_ids
# - etc.
```

## State

```bash
# Show state contents
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show <resource-address>

# Move resource to different state/target
terraform state mv old_addr new_addr

# Import existing infrastructure
terraform import aws_vpc.vpc id-of-existing-vpc

# Remove resources from state (without destroying)
terraform state rm <resource-address>

# This project uses remote state (S3 + DynamoDB lock for AWS, etc.)
```

## Fmt

```bash
# Format configuration files
terraform fmt

# Auto-fix and reformat
terraform fmt -recursive

# Check if formatting needed (exit code 1 if changes needed)
terraform fmt -check -recursive

# This project's CI (ci.yml) runs:
# terraform fmt -check -recursive
```

## Validate

```bash
# Validate configuration
terraform validate

# This project's CI (ci.yml) runs:
# terraform validate

# Common checks:
# - Valid HCL syntax
# - Required arguments present
# - Referenced arguments exist
```

## Graph

```bash
# Generate graph of resources
terraform graph

# Pipe to dot for visualization
terraform graph | dot -Tpng -o graph.png

# Show resource dependencies
terraform state graph
```

## Workspace

```bash
# List workspaces
terraform workspace list

# Select workspace
terraform workspace select dev

# Create new workspace
terraform workspace new staging

# Default workspace is "default" or "local"
```

## Providers

```bash
# List configured providers
terraform providers

# Force provider version
# In terraform.block { version "~> 1.5" }

# This project supports:
# - AWS provider (primary, reference implementation)
# - Azurerm provider (Azure modules)
# - Google provider (GCP modules)

# Provider versions are pinned in terraform/versions.tf
```

## Graph (Dependency)

```bash
# Show resource dependency graph
terraform state graph

# Example output structure:
# aws_vpc -> aws_subnet -> aws_instances -> aws_security_groups
# aws_ebs_volume -> aws_instance

# This helps understand:
# - Resource creation order
# - Dependencies between tiers
# - Impact of changes
```

## Troubleshooting

```bash
# Common issues
# "terraform: command not found" - install Terraform
# "E: Maximum reallocation count reached" - run terraform force-replace
# "Error acquiring the state lock" - another process has the lock
# "Unsupported argument" - check version compatibility
# "Too many recursive modules" - check module structure

# Debug mode
terraform plan -debug   # Full debug output
terraform apply -debug  # Debug apply

# State lock issues
# Wait for other process to finish
# Or run: terraform force-unlock <lock-id>

# Version compatibility
terraform init -upgrade   # Upgrade plugins

# This project's Terraform structure:
# - terraform/ root with -var="cloud=aws|azure|gcp"
# - terraform/cloud/aws/ modules (vpc, compute, database, ecr, monitoring, eks, jenkins)
# - terraform/cloud/azure/ and terraform/cloud/gcp/ for multi-cloud
# - versions.tf pins provider versions
# - backend.tf (or cloud/aws/backend.hcl) for remote state
```