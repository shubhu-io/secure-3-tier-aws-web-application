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

variable "region" {
  description = "AWS region"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Application security group ID"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN the ASG registers instances to"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN with the DB credentials"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
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

variable "volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Detailed CloudWatch monitoring (1-minute metrics, extra cost)"
  type        = bool
  default     = false
}

variable "services" {
  description = "Application services from stack.json: each gets an SSM image parameter + a docker-compose service. `public` marks the web entry point (mapped to host port 80)."
  type = list(object({
    name   = string
    port   = number
    public = bool
  }))
}

variable "health_check_grace_period" {
  description = "Seconds before ELB health checks start evaluating a new instance"
  type        = number
  default     = 180
}
