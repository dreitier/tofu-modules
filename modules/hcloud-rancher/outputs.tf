output "id" {
  value = hcloud_server.this.id
}

output "private_ip" {
  value = var.private_ip
}

output "url" {
  value = "https://${var.hostname}"
}
