# ============================================================================
# Root variables
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

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "azs" {
  description = "Availability zones. Defaults to the first two available in the region."
  type        = list(string)
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (ALB + NAT)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs (EC2)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "Private database subnet CIDRs (RDS)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "nat_gateway_count" {
  description = "NAT Gateways: 1 (dev, cheaper) or 2 (prod, one per AZ)"
  type        = number
  default     = 1
}

# --- Compute ---
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

# --- Database ---
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Multi-AZ RDS (production)"
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "app_user"
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
  type    = bool
  default = true
}

# --- DNS / TLS ---
variable "domain_name" {
  description = "Domain/subdomain for the app, e.g. app.example.com. Leave empty to skip ACM + Route 53."
  type        = string
  default     = ""
}

# --- Monitoring ---
variable "notification_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

# --- Repositories ---
variable "repositories" {
  description = "ECR repositories to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}
