# Azure CLI

Reference commands for Azure Command Line Interface. This project supports Azure as a secondary cloud (with modules under terraform/cloud/azure/).

## Installation

```bash
# macOS
brew install azure-cli

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y azure-cli

# Windows: Download from Azure CLI docs or use installer

# Or using pip (Azure CLI Python package)
pip install azure-cli

# Verify
az --version

# Login
az login
```

## Version Check

```bash
az --version
```

## Authentication

```bash
# Login interactively (browser)
az login

# Login with service principal (for CI/CD)
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>

# Set default subscription
az account set --subscription "<subscription-name-or-id>"

# List subscriptions
az account list

# Clear token cache
az login --clear

# This project uses service principals for CI/CD automation
```

## Core Commands

```bash
# Show current account
az account show

# Edge token for CLI (for ARM APIs)
az ad user show

# This project's Azure modules are under terraform/cloud/azure/
```

## Resource Group

```bash
# Create resource group
az group create --name secure-ntier-rg --location westeurope

# List resource groups
az group list

# Show resource group details
az group show --name secure-ntier-rg

# Delete resource group (destructive!)
az group delete --name secure-ntier-rg --yes --no-wait
```

## Networking

```bash
# Create Virtual Network
az network vnet create \
  --resource-group secure-ntier-rg \
  --name secure-vnet \
  --address-prefix 10.0.0.0/16

# Create subnet
az network vnet subnet create \
  --resource-group secure-ntier-rg \
  --vnet-name secure-vnet \
  --name app-subnet \
  --address-prefix 10.0.1.0/24

# Create Network Security Group
az network nsg create \
  --resource-group secure-ntier-rg \
  --name app-nsg

# This project's Azure implementation uses App Gateway + WAF, VMSS, and PostgreSQL Flexible Server
```

## AKS (Azure Kubernetes Service)

```bash
# Create AKS cluster
az aks create \
  --resource-group secure-ntier-rg \
  --name secure-ntier-aks \
  --node-count 2 \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group secure-ntier-rg \
  --name secure-ntier-aks

# List clusters
az aks list --resource-group secure-ntier-rg

# This project supports optional AKS deployment alongside EC2/VMSS path
```

## ACR (Azure Container Registry)

```bash
# Create ACR
az acr create \
  --resource-group secure-ntier-rg \
  --name secureacr \
  --sku Basic

# List ACrs
az acr list --resource-group secure-ntier-rg

# Login to ACR
az acr login --name secureacr

# This project's Azure ACR integration would push images similar to ECR in AWS
```

## Key Vault

```bash
# Create Key Vault
az keyvault create \
  --resource-group secure-ntier-rg \
  --name securekv \
  --location westeurope \
  --enable-soft-delete true

# Set a secret
az keyvault secret set \
  --vault-name securekv \
  --name DBPassword \
  --value "my-secret-password"

# Get a secret
az keyvault secret show \
  --vault-name securekv \
  --name DBPassword

# This project could use Azure Key Vault instead of AWS Secrets Manager
```

## PostgreSQL Flexible Server

```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group secure-ntier-rg \
  --name securepg \
  --location westeurope \
  --admin-user postgres \
  --admin-password <password> \
  --sku-name B_Standard_B1ms \
  --zone-redundancy Disabled

# List servers
az postgres flexible-server list --resource-group secure-ntier-rg

# This project supports PostgreSQL Flexible Server on Azure (private access)
```

## Storage

```bash
# Create storage account
az storage account create \
  --resource-group secure-ntier-rg \
  --name secureaccount \
  --location westeurope \
  --sku Standard_LRS

# List storage keys
az storage account keys list \
  --resource-group secure-ntier-rg \
  --name secureaccount

# This project's Azure storage would complement the VNet/VMSS implementation
```

## VMSS (Virtual Machine Scale Sets)

```bash
# Create VMSS
az vmss create \
  --resource-group secure-ntier-rg \
  --name vmss-app \
  --plan-capacity 2 \
  --image UbuntuLTS \
  --vm-size Standard_B1s \
  --vnet-name secure-vnet \
  --subnet app-subnet

# List VMSS
az vmss list --resource-group secure-ntier-rg

# This project supports Azure VMSS as the compute path (alternative to EC2 ASG)
```

## Troubleshooting

```bash
# Common issues
# "az: command not found" - install Azure CLI
# "Authentication failed" - run az login, check tenant/subscription
# "The subscription is not registered for" - register required providers
# "Permission denied" - ensure role assignment

# Debug
az ad signed-in-user show    # Show current user
az account list              # List accessible subscriptions

# This project's Azure support is secondary to AWS (primary reference implementation)
```