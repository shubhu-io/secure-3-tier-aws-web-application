# ============================================================================
# Jenkins module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_id" {
  description = "VPC network self_link for the firewall rule"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnetwork self_links (first hosts Jenkins)"
  type        = list(string)
}

variable "machine_type" {
  description = "Machine type for the Jenkins controller"
  type        = string
  default     = "e2-medium"
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to reach the Jenkins UI (8080) and agent port (50000)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
