# ============================================================================
# GKE module outputs
# ============================================================================

output "cluster_name" {
  description = "GKE cluster name (used by `gcloud container clusters get-credentials`)"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "GKE control plane endpoint"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to fetch the kubeconfig for this cluster"
  value       = local.kubeconfig_command
}
