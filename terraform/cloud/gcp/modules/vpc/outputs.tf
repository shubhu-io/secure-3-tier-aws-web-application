# ============================================================================
# VPC module outputs
# ============================================================================

output "network_id" {
  description = "VPC network self_link"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.this.name
}

output "public_subnet_ids" {
  description = "Public subnetwork self_links"
  value       = google_compute_subnetwork.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnetwork self_links"
  value       = google_compute_subnetwork.app[*].id
}

output "db_subnet_ids" {
  description = "Private database subnetwork self_links"
  value       = google_compute_subnetwork.db[*].id
}

output "nat_ips" {
  description = "Reserved NAT external IP addresses"
  value       = google_compute_address.nat[*].address
}
