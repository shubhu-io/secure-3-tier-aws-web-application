# ============================================================================
# EKS module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs for the control plane + node group"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.31"
}

variable "enable_public_access" {
  description = "Expose the EKS API endpoint publicly (kubectl from CI). Tighten with public_access_cidrs."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "EBS disk size (GiB) per node"
  type        = number
  default     = 20
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "ci_iam_arn" {
  description = "IAM principal ARN granted cluster admin for CI/CD (GitHub Actions / Jenkins user or role). Leave empty to skip."
  type        = string
  default     = ""
}
