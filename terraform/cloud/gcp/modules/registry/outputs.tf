# ============================================================================
# Registry module outputs
# ============================================================================

output "registry_url" {
  description = "Artifact Registry base URL (e.g. europe-west1-docker.pkg.dev/<project>)"
  value       = local.registry_url
}

output "image_repository_urls" {
  description = "Map of service name -> full container image repository URL"
  value       = local.image_repository_urls
}
