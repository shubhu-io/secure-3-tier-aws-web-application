# ============================================================================
# EKS module outputs
# ============================================================================

output "cluster_name" {
  description = "EKS cluster name (used by `aws eks update-kubeconfig`)"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group - trust it on the DB security group so pods can reach RDS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  description = "IAM role ARN assumed by the managed node group instances"
  value       = aws_iam_role.node.arn
}
