# ============================================================================
# ECR module variables
# ============================================================================

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)"
  type        = string
}

variable "repositories" {
  description = "List of repository keys to create (e.g. [\"backend\", \"frontend\"])"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE for rapid dev iteration, IMMUTABLE for strict production"
  type        = string
  default     = "MUTABLE"
}

variable "keep_last_images" {
  description = "Number of tagged images to keep in the lifecycle policy"
  type        = number
  default     = 10
}
