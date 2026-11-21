output "cluster_id" {
  description = "ID of the cluster (c-m-xxxx), as used by most rancher2 resources"
  value       = rancher2_cluster_v2.this.cluster_v1_id
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = rancher2_cluster_v2.this.name
}

output "node_command" {
  description = "Command to register additional nodes with the cluster (append the roles, e.g. --worker)"
  value       = local.node_command
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig of the cluster: the authorized cluster endpoint (direct to the API server) when enabled, otherwise through Rancher"
  value       = local.kube_config
  sensitive   = true
}

output "kube_config_oidc" {
  description = "Kubeconfig for people: direct API endpoint, login with kubelogin against the OIDC provider (no secret inside)"
  value       = local.kube_config_oidc
}

output "kube_config_rancher" {
  description = "Kubeconfig through the Rancher proxy (request size limited – large Helm releases fail)"
  value       = rancher2_cluster_v2.this.kube_config
  sensitive   = true
}

output "registration_token_hashes" {
  description = "SHA-256 per registration token name – to match a token from the Rancher UI without revealing it"
  value       = { for k, v in nonsensitive(local.registration_tokens) : k => sha256(v) }
}
