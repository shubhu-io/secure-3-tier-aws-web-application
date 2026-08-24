# ============================================================================
# GKE module variables
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
  description = "VPC network self_link"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnetwork self_links"
  type        = list(string)
}

variable "machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.31.0"
}

variable "gke_node_tags" {
  description = "Network tags applied to nodes (allowed to reach the DB)"
  type        = list(string)
  default     = ["gke-node"]
}
