# ============================================================================
# Security module - layered security groups
#
#   Internet ─▶ ALB SG ─▶ App SG ─▶ DB SG
#
# Security Groups are stateful: return traffic is allowed automatically.
# This module only creates groups; the WAF, HTTPS and IAM layers are handled
# by their own modules / root configuration.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- ALB security group: the ONLY group reachable from the internet ---
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB: HTTPS/HTTP from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere (redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Tier        = "public"
    Environment = var.environment
  }
}

# --- Application security group: reachable ONLY from the ALB SG ---
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "App instances: traffic from ALB only, all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic (port 80) from the ALB security group"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # No inbound SSH. Admin access uses AWS Systems Manager Session Manager
  # (permitted via the instance IAM role, no open ports required).

  egress {
    description = "All outbound (patches, image pulls via NAT, DB connections)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-app-sg"
    Tier        = "app"
    Environment = var.environment
  }
}

# --- Database security group: reachable ONLY from the App SG ---
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "RDS: PostgreSQL from the app security group only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from the application security group"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-db-sg"
    Tier        = "db"
    Environment = var.environment
  }
}
