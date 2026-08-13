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

output "backend_image_param" {
  description = "SSM parameter name holding the deployed backend image URI"
  value       = local.backend_image_param
}

output "frontend_image_param" {
  description = "SSM parameter name holding the deployed frontend image URI"
  value       = local.frontend_image_param
}
