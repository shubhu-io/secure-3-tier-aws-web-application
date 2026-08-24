# ============================================================================
# Compute module variables
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
  description = "GCP project ID (for IAM bindings)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnetwork self_links"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application listens on (LB target / health check)"
  type        = number
  default     = 80
}

variable "services" {
  description = "Application services from stack.json (any-typed to mirror the manifest)"
  type        = any
}

variable "machine_type" {
  description = "GCP machine type for the instance template"
  type        = string
  default     = "e2-small"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "image_repository_urls" {
  description = "Map of service name -> full Artifact Registry repository URL"
  type        = map(string)
}

variable "db_secret_ref" {
  description = "Secret Manager secret id holding DB credentials"
  type        = string
}

variable "db_port" {
  description = "Database port (5432 PostgreSQL)"
  type        = number
  default     = 5432
}
