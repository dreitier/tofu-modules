output "public_url" {
  description = "Base URL for the BOM upload from CI (only /api/v1/bom and /api/version are routed)"
  value       = "https://${var.public_hostname}"
}

output "internal_url" {
  value = "https://${var.internal_hostname}"
}
