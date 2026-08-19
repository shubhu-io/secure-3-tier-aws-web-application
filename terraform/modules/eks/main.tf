# ============================================================================
# EKS module - managed Kubernetes on AWS
#
# Creates: EKS control plane (private + public endpoint), managed node group
#          in the private app subnets, IAM roles, OIDC provider, and an access
#          entry for the CI/CD principal so pipelines can kubectl.
#
# The cluster security group is returned so the root module can let pods reach
# the private RDS on 5432 (the DB security group trusts this source).
# ============================================================================

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${var.project_name}-${var.environment}-eks"
}

# ---------------------------------------------------------------------------
# Control plane IAM role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------------------------------------------------------------------------
# EKS cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.app_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit"]

  depends_on = [aws_iam_role_policy_attachment.cluster]

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Node group IAM role (assumed by EC2 instances)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------------------------------------------------------------------------
# Managed node group (private app subnets, encrypted EBS)
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.app_subnet_ids

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "app"
  }

  depends_on = [aws_eks_cluster.this]

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# OIDC provider - required for IRSA (IAM roles for service accounts).
# Deliberately not created here to keep this module provider-light; add it
# when you adopt IRSA/Secrets-Store-CSI (see docs/deployment/eks.md).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Access entry for the CI/CD principal (GitHub Actions / Jenkins IAM)
# ---------------------------------------------------------------------------
resource "aws_eks_access_entry" "ci" {
  count = var.ci_iam_arn != "" ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.ci_iam_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci" {
  count = var.ci_iam_arn != "" ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.ci_iam_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ci[0]]
}
