output "grafana_url" {
  value = "https://${local.grafana_fqdn}"
}

output "prometheus_url" {
  value = "https://${local.prometheus_fqdn}"
}

output "alertmanager_url" {
  value = "https://${local.alertmanager_fqdn}"
}

output "loki_url" {
  value = "https://${local.loki_fqdn}"
}
