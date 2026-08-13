# ============================================================================
# Root module - wires every component together
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Default to the first two AZs if the caller did not pin them
  azs = var.azs != null ? var.azs : [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
  ]
}

# ---------------------------------------------------------------------------
# 1. Network
# ---------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  azs                      = local.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  app_subnet_cidrs         = var.app_subnet_cidrs
  db_subnet_cidrs          = var.db_subnet_cidrs
  nat_gateway_count        = var.nat_gateway_count
  enable_flow_logs         = true
  flow_logs_retention_days = var.environment == "prod" ? 90 : 14
}

# ---------------------------------------------------------------------------
# 2. Security groups
# ---------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  app_port     = 80
  db_port      = 5432
}

# ---------------------------------------------------------------------------
# 3. TLS + DNS (optional - only when domain_name is set)
# ---------------------------------------------------------------------------
data "aws_route53_zone" "selected" {
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

# ---------------------------------------------------------------------------
# 4. Container registry
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  repositories = var.repositories
}

# ---------------------------------------------------------------------------
# 5. Load balancer + WAF
# ---------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  alb_sg_id       = module.security.alb_sg_id
  app_port        = 80
  certificate_arn = var.domain_name != "" ? aws_acm_certificate.this[0].arn : ""
  enable_waf      = true
}

# Alias record: app.example.com -> ALB
resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# ---------------------------------------------------------------------------
# 6. Database
# ---------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  db_subnet_ids         = module.vpc.db_subnet_ids
  db_sg_id              = module.security.db_sg_id
  db_instance_class     = var.db_instance_class
  db_multi_az           = var.db_multi_az
  db_allocated_storage  = var.db_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  backup_retention_days = var.backup_retention_days
  deletion_protection   = var.deletion_protection
  skip_final_snapshot   = var.skip_final_snapshot
}

# ---------------------------------------------------------------------------
# 7. Compute (EC2 + ASG)
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name               = var.project_name
  environment                = var.environment
  region                     = var.aws_region
  app_subnet_ids             = module.vpc.app_subnet_ids
  app_sg_id                  = module.security.app_sg_id
  target_group_arn           = module.alb.target_group_arn
  db_secret_arn              = module.database.db_secret_arn
  instance_type              = var.instance_type
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  desired_capacity           = var.asg_desired_capacity
  enable_detailed_monitoring = var.environment == "prod"
}

# ---------------------------------------------------------------------------
# 8. Monitoring
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  notification_email      = var.notification_email
  asg_name                = module.compute.asg_name
  alb_arn                 = module.alb.alb_arn
  target_group_arn        = module.alb.target_group_arn
  db_instance_id          = module.database.db_instance_id
  db_allocated_storage_gb = var.db_allocated_storage
}

# ---------------------------------------------------------------------------
# 9. Auditing - CloudTrail (multi-region)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail"
  force_destroy = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "CloudTrailBucketPolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "CloudTrailBucketPolicyCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# ---------------------------------------------------------------------------
# 10. CI/CD IAM policy - attach to the GitHub Actions IAM user
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "cicd" {
  name        = "${var.project_name}-${var.environment}-cicd-policy"
  description = "Least-privilege permissions for GitHub Actions to deploy the app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:*:repository/${var.project_name}-${var.environment}-backend",
          "arn:aws:ecr:${var.aws_region}:*:repository/${var.project_name}-${var.environment}-frontend",
        ]
      },
      {
        Sid    = "UpdateImageParams"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/secure-ntier/${var.environment}/backend-image",
          "arn:aws:ssm:${var.aws_region}:*:parameter/secure-ntier/${var.environment}/frontend-image",
        ]
      },
      {
        Sid    = "TriggerInstanceRefresh"
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeInstanceRefreshes"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "HealthChecks"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
        ]
        Resource = ["*"]
      }
    ]
  })
}

output "cicd_policy_arn" {
  description = "ARN of the CI/CD IAM policy to attach to the GitHub Actions user"
  value       = aws_iam_policy.cicd.arn
}
