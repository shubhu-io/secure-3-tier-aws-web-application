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

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to place the security group in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (first one hosts the Jenkins box)"
  type        = list(string)
}

variable "cicd_policy_arn" {
  description = "ARN of the CI/CD policy granted to the GitHub Actions user (reused for Jenkins)"
  type        = string
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to reach the Jenkins UI (8080) and agent port (50000). WARNING: default 0.0.0.0/0 is open to the world - lock this down for anything but a throwaway lab."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for the Jenkins controller"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Root EBS volume size (GB) - Jenkins home + image cache live here"
  type        = number
  default     = 30
}

variable "key_name" {
  description = "Optional EC2 key pair for SSH. Leave empty to use SSM Session Manager."
  type        = string
  default     = ""
}

variable "kubectl_version" {
  description = "kubectl version pinned inside the controller image (should match the EKS cluster version)"
  type        = string
  default     = "v1.31.0"
}
