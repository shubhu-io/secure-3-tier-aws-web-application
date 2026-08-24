# ============================================================================
# Jenkins module outputs
# ============================================================================

output "jenkins_url" {
  description = "Jenkins controller URL"
  value       = "http://${google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip}:8080"
}

output "jenkins_external_ip" {
  description = "Jenkins controller external IP"
  value       = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
}
