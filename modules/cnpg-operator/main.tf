# CloudNativePG operator + Barman Cloud plugin (backups to object storage). The plugin chart needs
# cert-manager (mTLS between operator and plugin) and must run in the operator's namespace.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "operator" {
  name       = "cnpg"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.operator_chart_version

  values = [yamlencode({
    resources = var.resources.operator
    monitoring = {
      podMonitorEnabled = var.monitoring_enabled
    }
  })]
}

resource "helm_release" "barman_cloud" {
  name       = "barman-cloud"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "plugin-barman-cloud"
  version    = var.barman_cloud_chart_version

  values = [yamlencode({ resources = var.resources.barman_cloud })]

  depends_on = [helm_release.operator]
}
