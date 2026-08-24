# ============================================================================
# Root variables - Azure implementation.
#
# Every variable forwarded by terraform/main.tf (module "azure") is declared
# here with the correct type. Unused variables are still declared (they are
# part of the shared multi-cloud contract) but may be ignored in logic.
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
  default     = "secure-ntier"
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region (e.g. westeurope)"
  type        = string
  default     = "westeurope"
}

variable "vpc_cidr" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones. Defaults to [\"1\", \"2\"] when null."
  type        = list(string)
  default     = null
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (Application Gateway + NAT)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs (VMSS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "Private database subnet CIDRs (PostgreSQL Flexible Server)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "nat_gateway_count" {
  description = "NAT Gateways: 1 (dev, cheaper) or 2 (prod, one per AZ)"
  type        = number
  default     = 1
}

variable "alb_deletion_protection" {
  description = "Prevent accidental Application Gateway deletion (production)"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Store Application Gateway access logs (requires a Log Analytics workspace)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain/subdomain for the app, e.g. app.example.com. Leave empty to skip custom TLS."
  type        = string
  default     = ""
}

variable "notification_email" {
  description = "Email for monitoring alert notifications"
  type        = string
}

variable "repositories" {
  description = "Container repositories to create in ACR (one per service in stack.json)"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "db_name" {
  description = "Name of the PostgreSQL database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL administrator login"
  type        = string
  default     = "app_user"
}

variable "db_multi_az" {
  description = "Zone-redundant PostgreSQL (production)"
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  description = "Database allocated storage (GB)"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Protect the database from accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip creating a final backup on destroy (dev convenience)"
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum number of VMSS instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of VMSS instances"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of VMSS instances"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Azure VM size for the scale set"
  type        = string
  default     = "Standard_B1s"
}

variable "db_sku" {
  description = "Azure PostgreSQL Flexible Server SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "enable_aks" {
  description = "Provision an AKS cluster + node pool"
  type        = bool
  default     = false
}

variable "aks_node_count" {
  description = "Number of AKS nodes in the default node pool"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for the AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for the AKS control plane"
  type        = string
  default     = "1.31.0"
}

variable "aks_ci_principal_id" {
  description = "Object ID of the CI/CD principal (service principal / managed identity) granted AKS + deploy permissions"
  type        = string
  default     = ""
}

variable "enable_jenkins" {
  description = "Provision a self-hosted Jenkins controller on a VM (alternative to GitHub Actions)"
  type        = bool
  default     = false
}

variable "jenkins_vm_size" {
  description = "VM size for the Jenkins controller"
  type        = string
  default     = "Standard_B2s"
}

variable "jenkins_ingress_cidrs" {
  description = "CIDRs allowed to reach the Jenkins UI (8080) + agent port (50000). WARNING: default is open - lock this down."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_admin_username" {
  description = "Admin username for the Jenkins controller VM"
  type        = string
  default     = "jenkinsadmin"
}
