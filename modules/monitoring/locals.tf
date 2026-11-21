locals {
  # Kubeconfig from the cluster unit (Rancher-proxied) – same parsing as modules/monitoring
  kubeconfig = yamldecode(var.kube_config)

  kubeconfig_context_name = try(local.kubeconfig["current-context"], local.kubeconfig.contexts[0].name)
  kubeconfig_context      = one([for c in local.kubeconfig.contexts : c.context if c.name == local.kubeconfig_context_name])
  kubeconfig_cluster      = one([for c in local.kubeconfig.clusters : c.cluster if c.name == local.kubeconfig_context.cluster])
  kubeconfig_user         = one([for u in local.kubeconfig.users : u.user if u.name == local.kubeconfig_context.user])

  kubernetes_host           = local.kubeconfig_cluster.server
  kubernetes_ca_certificate = try(base64decode(local.kubeconfig_cluster["certificate-authority-data"]), null)
  kubernetes_insecure       = try(local.kubeconfig_cluster["insecure-skip-tls-verify"], false)
  kubernetes_client_cert    = try(base64decode(local.kubeconfig_user["client-certificate-data"]), null)
  kubernetes_client_key     = try(base64decode(local.kubeconfig_user["client-key-data"]), null)
  kubernetes_token          = try(local.kubeconfig_user.token, null)
}

locals {
  kps_fullname         = "kube-prometheus-stack"
  prometheus_url       = "http://${local.kps_fullname}-prometheus.${var.namespaces.monitoring}.svc.cluster.local:9090"
  alertmanager_url     = "http://${local.kps_fullname}-alertmanager.${var.namespaces.monitoring}.svc.cluster.local:9093"
  blackbox_fullname    = "blackbox-exporter"
  blackbox_port        = 9115
  loki_url             = "http://loki.${var.namespaces.loki}.svc.cluster.local:3100"
  grafana_fqdn         = "grafana.${var.internal_domain}"
  prometheus_fqdn      = "prometheus.${var.internal_domain}"
  alertmanager_fqdn    = "alertmanager.${var.internal_domain}"
  loki_fqdn            = "loki.${var.internal_domain}"
  external_secret_api  = "external-secrets.io/v1"
  grafana_oidc_secret  = "grafana-oidc"
  grafana_admin_secret = "grafana-admin"
  loki_s3_secret       = "loki-s3"
  heartbeat_secret     = "alertmanager-heartbeat"
}
