output "gateway_setup_key" {
  description = "One-off setup key of the routing peer (valid 24 h): terragrunt output -raw gateway_setup_key"
  value       = netbird_setup_key.gateway.key
  sensitive   = true
}
