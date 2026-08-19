# ============================================================================
# Compute module - EC2 Launch Template + Auto Scaling Group
#
# Creates: AMI lookup, launch template, IAM instance role (least privilege),
#          SSM parameters holding the current image URIs, ASG, scaling policy.
# ============================================================================

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  image_params = { for s in var.services : s.name => "/${var.project_name}/${var.environment}/${s.name}-image" }
}

# ---------------------------------------------------------------------------
# AMI - Ubuntu 24.04 (LTS), current version
# ---------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# IAM instance role - least privilege for what the user-data script needs
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "instance_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${local.name_prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "instance" {
  name = "${local.name_prefix}-instance-policy"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMReadImageParams"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          for s in var.services :
          "arn:aws:ssm:${var.region}:*:parameter/${var.project_name}/${var.environment}/${s.name}-image"
        ]
      },
      {
        Sid    = "ReadDbSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [var.db_secret_arn]
      },
      {
        Sid    = "EcrPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:${var.region}:*:log-group:/${var.project_name}-${var.environment}/*:*"]
      }
    ]
  })
}

# Managed policy that lets the SSM Agent register + start sessions
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name
}

# ---------------------------------------------------------------------------
# SSM Parameters - the "deploy pointer". CI/CD updates these (one per service),
# then triggers an instance refresh; new instances pull the new images at boot.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "image" {
  for_each = { for s in var.services : s.name => s }

  name  = local.image_params[each.key]
  type  = "String"
  value = "pending"

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Launch template
# ---------------------------------------------------------------------------
resource "aws_launch_template" "this" {
  name          = "${local.name_prefix}-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    region        = var.region
    environment   = var.environment
    project_name  = var.project_name
    app_name      = local.name_prefix
    secret_name   = var.db_secret_arn
    services_json = jsonencode(var.services)
  }))

  # Encrypted EBS root volume
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # IMDSv2 required - blocks SSRF-style token stealing
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${local.name_prefix}-app"
      Environment = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "${local.name_prefix}-app-volume"
      Environment = var.environment
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling Group - across private app subnets, ELB health checks
# ---------------------------------------------------------------------------
resource "aws_autoscaling_group" "this" {
  name             = "${local.name_prefix}-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.app_subnet_ids

  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = 300
  protect_from_scale_in     = true

  # Rolling refresh settings (used when Terraform changes the group and also
  # matched by manual `aws autoscaling start-instance-refresh` calls from CI)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Target tracking scaling policy - CPU at 70%
# ---------------------------------------------------------------------------
resource "aws_autoscaling_policy" "cpu" {
  name                      = "${local.name_prefix}-cpu-scaling"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
