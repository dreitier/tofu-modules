output "network_id" {
  value = hcloud_network.this.id
}

output "network_name" {
  value = hcloud_network.this.name
}

output "ip_range" {
  value = hcloud_network.this.ip_range
}

output "gateway_ip" {
  value       = var.gateway_ip
  description = "Private IP of the gateway server (route target)"
}

output "network_router_ip" {
  value       = cidrhost(var.ip_range, 1)
  description = "Hetzner's router in the network – next hop of the servers' default route"
}

output "placement_group_ids" {
  value = { for k, g in hcloud_placement_group.this : k => g.id }
}

output "ssh_key_ids" {
  value       = [for k in hcloud_ssh_key.admin : k.id]
  description = "IDs of the admin SSH keys"
}
