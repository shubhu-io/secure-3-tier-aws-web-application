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

# --- Load balancer ---
variable "alb_deletion_protection" {
  description = "Prevent accidental ALB deletion (production)"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Store ALB access logs in an S3 bucket"
  type        = bool
  default     = false
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

variable "enhanced_monitoring_interval" {
  description = "RDS Enhanced Monitoring interval in seconds (0 = disabled, 60 = 1-min). Adds a small per-hour cost; enable for prod."
  type        = number
  default     = 0
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

variable "ecr_push_principal_arns" {
  description = "IAM principal ARNs (CI/CD role or user) allowed to push images to ECR via the repository policy. Leave empty to rely on the root IAM policy alone."
  type        = list(string)
  default     = []
}

# --- Kubernetes (EKS) ---
variable "enable_eks" {
  description = "Provision an EKS cluster + managed node group (costly; opt-in)"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_min_size" {
  type    = number
  default = 2
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_max_size" {
  type    = number
  default = 4
}

variable "eks_ci_iam_arn" {
  description = "IAM principal ARN granted cluster admin for CI/CD (GitHub Actions / Jenkins user or role). Leave empty to skip."
  type        = string
  default     = ""
}

# --- Jenkins (optional, alternative to GitHub Actions) ---
variable "enable_jenkins" {
  description = "Provision a self-hosted Jenkins controller on EC2 (costly; opt-in). Overlaps with GitHub Actions - run one engine per repo."
  type        = bool
  default     = false
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for the Jenkins controller"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_ingress_cidrs" {
  description = "CIDRs allowed to reach the Jenkins UI (8080) + agent port (50000). WARNING: default is open to the world - lock this down."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_key_name" {
  description = "Optional EC2 key pair for SSH to the Jenkins box. Empty = SSM Session Manager instead."
  type        = string
  default     = ""
}

variable "jenkins_kubectl_version" {
  description = "kubectl version pinned inside the Jenkins controller image (match the EKS cluster version)"
  type        = string
  default     = "v1.31.0"
}
