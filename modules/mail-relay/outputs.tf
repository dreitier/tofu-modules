output "smtp_host" {
  description = "In-cluster SMTP host (port 25, no auth, no TLS)"
  value       = "${var.release_name}-postfix.${var.namespace}.svc.cluster.local"
}
