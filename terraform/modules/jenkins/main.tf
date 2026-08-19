# ============================================================================
# Jenkins module - self-hosted CI/CD controller (alternative to GitHub Actions)
#
# Creates: AMI lookup, security group (UI + agent ports), IAM instance role
#          that reuses the CI/CD policy, EC2 instance running a Jenkins
#          controller container (LTS + AWS CLI v2 + kubectl + docker CLI).
#
# The controller's built-in node is the pipeline agent ("docker && linux"):
# the container mounts the host Docker socket for `docker build` and reaches
# the EC2 metadata service (IMDSv2, hop limit 2) so the AWS CLI inherits the
# instance role - no long-lived keys on the box.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
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
# IAM instance role - reuses the CI/CD policy so Jenkins can deploy the app.
# The pipeline also falls back to these instance credentials when no access
# keys are configured in Jenkins.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "jenkins_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "${local.name_prefix}-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cicd" {
  role       = aws_iam_role.jenkins.name
  policy_arn = var.cicd_policy_arn
}

# SSM Session Manager access - used to troubleshoot the box without SSH
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${local.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# ---------------------------------------------------------------------------
# Security group - Jenkins UI (8080) + inbound agent traffic (50000)
# ---------------------------------------------------------------------------
resource "aws_security_group" "jenkins" {
  name        = "${local.name_prefix}-jenkins-sg"
  description = "Jenkins controller: UI 8080, agents 50000"
  vpc_id      = var.vpc_id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  ingress {
    description = "Jenkins inbound agent traffic"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-jenkins-sg"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# EC2 instance - runs the Jenkins controller container
# ---------------------------------------------------------------------------
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    region          = var.region
    environment     = var.environment
    project_name    = var.project_name
    kubectl_version = var.kubectl_version
  }))

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # IMDSv2 required. Hop limit 2 lets the Jenkins *container* (one NAT hop
  # from the host) reach the metadata service and inherit the instance role.
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "${local.name_prefix}-jenkins"
    Environment = var.environment
  }
}
