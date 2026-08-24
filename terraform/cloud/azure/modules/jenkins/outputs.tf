# ============================================================================
# Jenkins module outputs
# ============================================================================

output "jenkins_instance_id" {
  description = "Jenkins VM resource ID"
  value       = azurerm_linux_virtual_machine.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins controller"
  value       = azurerm_public_ip.jenkins.ip_address
}

output "jenkins_url" {
  description = "Jenkins controller URL"
  value       = "http://${azurerm_public_ip.jenkins.ip_address}:8080"
}
