output "webhook_url" {
  description = "Webhook URL for the Trivy Operator (operator.webhookBroadcastURL)"
  value       = "http://${local.name}.${var.namespace}.svc:8080/"
}
