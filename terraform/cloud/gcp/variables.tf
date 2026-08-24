# ============================================================================
# GCP root module variables
# ----------------------------------------------------------------------------
# Every variable passed by the root dispatcher (terraform/main.tf -> module
# "gcp") is declared here, with the exact names and types expected. Unused
# variables (e.g. enable_alb_access_logs, alb_deletion_protection) are still
# declared for interface parity; they are intentionally not wired into logic
# where GCP has no direct equivalent (see README).
# ============================================================================

variable "project" {
  description = "GCP project ID (required - empty is a user error)"
  type        = string
  default     = ""
}

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

variable "region" {
  description = "GCP region (e.g. europe-west1)"
  type        = string
  default     = "europe-west1"
}

variable "vpc_cidr" {
  description = "VPC network CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Zones (defaults to <region>-a / <region>-b when null)"
  type        = list(string)
  default     = null
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (load balancer + NAT)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs (compute)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "Private database subnet CIDRs"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "nat_gateway_count" {
  description = "Number of reserved NAT IPs (1 for dev, 2 for prod HA)"
  type        = number
  default     = 1
}

variable "alb_deletion_protection" {
  description = "Prevent accidental LB deletion (no direct GCP equivalent; documented)"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Store LB access logs (GCP uses Logging exports; not wired here)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain/subdomain for the app (optional TLS). Leave empty to skip."
  type        = string
  default     = ""
}

variable "notification_email" {
  description = "Email for alarm/alert notifications"
  type        = string
  default     = ""
}

variable "repositories" {
  description = "Container repositories to create (one per service in stack.json)"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "app_user"
}

variable "db_multi_az" {
  description = "Multi-zone / regional Cloud SQL (production failover)"
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  description = "Database allocated storage (GB)"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  description = "Cloud SQL has no final-snapshot concept; kept for interface parity"
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum number of compute instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of compute instances"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of compute instances"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GCP machine type for the managed instance group"
  type        = string
  default     = "e2-small"
}

variable "db_tier" {
  description = "Cloud SQL tier (e.g. db-f1-micro)"
  type        = string
  default     = "db-f1-micro"
}

variable "enable_gke" {
  description = "Provision a GKE cluster + node pool"
  type        = bool
  default     = false
}

variable "gke_node_count" {
  type    = number
  default = 2
}

variable "gke_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "gke_kubernetes_version" {
  type    = string
  default = "1.31.0"
}

variable "enable_jenkins" {
  description = "Provision a self-hosted Jenkins controller on a VM"
  type        = bool
  default     = false
}

variable "jenkins_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "jenkins_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
