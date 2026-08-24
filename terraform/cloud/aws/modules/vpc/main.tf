# ============================================================================
# VPC module - network foundation
# Creates: VPC, Internet Gateway, public/app/db subnets, route tables,
#          NAT Gateway(s), Network ACLs per tier, VPC Flow Logs.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Subnets
# Public subnets: ALB + NAT. map_public_ip_on_launch only affects EC2 launched
# here directly (none in this design), but is kept for flexibility.
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-${element(var.azs, count.index)}"
    Tier        = "public"
    Environment = var.environment
  }
}

resource "aws_subnet" "app" {
  count                   = length(var.app_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.app_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-app-${element(var.azs, count.index)}"
    Tier        = "app"
    Environment = var.environment
  }
}

resource "aws_subnet" "db" {
  count                   = length(var.db_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.db_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-db-${element(var.azs, count.index)}"
    Tier        = "db"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Route tables
# Public: 0.0.0.0/0 -> Internet Gateway
# App:    0.0.0.0/0 -> NAT Gateway(s)
# DB:     no default route (private only, no internet)
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${local.name_prefix}-public-rt"
    Tier        = "public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway(s) - one per AZ when nat_gateway_count=2, one shared when =1
resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${local.name_prefix}-nat-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

# One app route table per NAT. With a single NAT both app subnets share it.
resource "aws_route_table" "app" {
  count  = var.nat_gateway_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name        = "${local.name_prefix}-app-rt-${count.index + 1}"
    Tier        = "app"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index % var.nat_gateway_count].id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-db-rt"
    Tier        = "db"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

# ---------------------------------------------------------------------------
# Network ACLs (defense in depth). NACLs are stateless: they need BOTH
# inbound and outbound rules for a connection to work.
# Primary isolation is subnet routing + security groups; NACLs add a second
# firewall layer that also protects against misconfigured SGs.
# ---------------------------------------------------------------------------

# --- Public NACL: 80/443 in, ephemeral return in, all out ---
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-public-nacl"
    Tier        = "public"
    Environment = var.environment
  }
}

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Return traffic for connections initiated from inside the VPC (e.g. NAT)
resource "aws_network_acl_rule" "public_in_ephemeral_vpc" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Return traffic from the internet to NAT/ALB on ephemeral ports
resource "aws_network_acl_rule" "public_in_ephemeral_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public.id
}

# --- App NACL: 80 (ALB -> nginx) in, ephemeral VPC in, all out ---
resource "aws_network_acl" "app" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-app-nacl"
    Tier        = "app"
    Environment = var.environment
  }
}

resource "aws_network_acl_rule" "app_in_http" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = join(",", var.public_subnet_cidrs) != "" ? var.public_subnet_cidrs[0] : "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "app_in_http_b" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = length(var.public_subnet_cidrs) > 1 ? var.public_subnet_cidrs[1] : var.public_subnet_cidrs[0]
  from_port      = 80
  to_port        = 80
}

# Return traffic for outbound connections (NAT / VPC)
resource "aws_network_acl_rule" "app_in_ephemeral_vpc" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "app_out_all" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  network_acl_id = aws_network_acl.app.id
}

# --- DB NACL: 5432 (app -> db) in, ephemeral VPC in, ephemeral out ---
resource "aws_network_acl" "db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-db-nacl"
    Tier        = "db"
    Environment = var.environment
  }
}

resource "aws_network_acl_rule" "db_in_postgres" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = join(",", var.app_subnet_cidrs) != "" ? var.app_subnet_cidrs[0] : "0.0.0.0/0"
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "db_in_postgres_b" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = length(var.app_subnet_cidrs) > 1 ? var.app_subnet_cidrs[1] : var.app_subnet_cidrs[0]
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "db_in_ephemeral_vpc" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Responses back to the app on ephemeral ports (DB doesn't talk to the
# internet: the DB route table has no default route, so even a wide NACL
# egress cannot reach the internet).
resource "aws_network_acl_rule" "db_out_ephemeral_vpc" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "db_out_ephemeral_all" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  network_acl_id = aws_network_acl.db.id
}

# ---------------------------------------------------------------------------
# VPC Flow Logs -> CloudWatch Logs
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc-flow-log/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_days

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count                    = var.enable_flow_logs ? 1 : 0
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = 60

  tags = {
    Environment = var.environment
  }
}
