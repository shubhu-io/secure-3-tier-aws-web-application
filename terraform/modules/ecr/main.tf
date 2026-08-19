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
