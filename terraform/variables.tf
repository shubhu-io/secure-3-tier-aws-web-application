# ============================================================================
# Root variables — AWS platform inputs
# ============================================================================

# --- Shared (networking, compute, database, etc.) ----------------------------
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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones. Defaults to the first two available."
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
  description = "NAT Gateways: 1 (dev, cheaper) or 2 (prod, one per AZ)"
  type        = number
  default     = 1
}

variable "alb_deletion_protection" {
  description = "Prevent accidental load-balancer deletion (production)"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Store load-balancer access logs"
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
  description = "Multi-AZ RDS instance (production)"
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
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
  type    = bool
  default = true
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

# --- AWS-specific ------------------------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "aws_db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "aws_enhanced_monitoring_interval" {
  description = "RDS Enhanced Monitoring interval in seconds (0 = disabled)"
  type        = number
  default     = 0
}

variable "aws_ecr_push_principal_arns" {
  description = "IAM principal ARNs allowed to push to ECR"
  type        = list(string)
  default     = []
}

variable "aws_enable_eks" {
  description = "Provision an EKS cluster + managed node group (OPTIONAL — everything runs on EC2 by default; set true only if you want K8s alongside EC2)"
  type        = bool
  default     = false
}

variable "aws_eks_cluster_version" {
  type    = string
  default = "1.31"
}

variable "aws_eks_node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "aws_eks_node_min_size" {
  type    = number
  default = 2
}

variable "aws_eks_node_desired_size" {
  type    = number
  default = 2
}

variable "aws_eks_node_max_size" {
  type    = number
  default = 4
}

variable "aws_eks_ci_iam_arn" {
  description = "IAM principal ARN granted cluster access for CI/CD"
  type        = string
  default     = ""
}

variable "aws_enable_jenkins" {
  description = "Provision a self-hosted Jenkins controller on EC2"
  type        = bool
  default     = false
}

variable "aws_jenkins_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "aws_jenkins_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "aws_jenkins_key_name" {
  type    = string
  default = ""
}

variable "aws_jenkins_kubectl_version" {
  type    = string
  default = "v1.31.0"
}
