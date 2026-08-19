# ============================================================================
# Jenkins module outputs
# ============================================================================

output "jenkins_instance_id" {
  description = "EC2 instance ID of the Jenkins controller"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins controller"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins controller URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_sg_id" {
  description = "Security group ID of the Jenkins controller"
  value       = aws_security_group.jenkins.id
}
