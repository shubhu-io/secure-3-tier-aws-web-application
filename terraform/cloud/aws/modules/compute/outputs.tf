# ============================================================================
# Compute module outputs
# ============================================================================

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.this.id
}

output "instance_role_arn" {
  description = "Instance IAM role ARN"
  value       = aws_iam_role.instance.arn
}

output "instance_profile_name" {
  description = "Instance IAM instance profile name"
  value       = aws_iam_instance_profile.instance.name
}

output "image_params" {
  description = "Map of service name -> SSM parameter holding its deployed image URI"
  value       = local.image_params
}
