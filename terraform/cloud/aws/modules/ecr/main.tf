# ============================================================================
# ECR module - private container registries
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repositories)
  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Least-privilege repository policy: the app instances' role may pull the
# image, the CI/CD principal (GitHub Actions / Jenkins role or user) may push.
# Applied only when the caller supplies principals - otherwise access is
# governed purely by the IAM policies in the root module.
resource "aws_ecr_repository_policy" "this" {
  for_each   = length(var.pull_principals) > 0 || length(var.push_principals) > 0 ? aws_ecr_repository.this : {}
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [for p in var.pull_principals : {
        Sid       = "AllowPull"
        Effect    = "Allow"
        Principal = { AWS = p }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }],
      [for p in var.push_principals : {
        Sid       = "AllowPush"
        Effect    = "Allow"
        Principal = { AWS = p }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }]
    )
  })
}

# Keep only the last N tagged images + drop untagged images after 14 days
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.keep_last_images} tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last_images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output map of repo name -> URL (e.g. backend, frontend)
output "repository_urls" {
  description = "Map of repository key to repository URL"
  value = {
    for key in var.repositories :
    key => aws_ecr_repository.this[key].repository_url
  }
}

output "repository_names" {
  description = "Map of repository key to repository name"
  value = {
    for key in var.repositories :
    key => aws_ecr_repository.this[key].name
  }
}
