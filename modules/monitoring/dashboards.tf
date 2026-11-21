# Own dashboards (manifests/dashboards/*.json) as ConfigMaps for Grafana's sidecar (label grafana_dashboard=1,
# folder from the annotation)
resource "kubernetes_config_map_v1" "dashboard" {
  for_each = fileset("${path.module}/manifests/dashboards", "*.json")

  metadata {
    name        = "dashboard-${trimsuffix(each.value, ".json")}"
    namespace   = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
    labels      = { grafana_dashboard = "1" }
    annotations = { grafana_dashboard_folder = "dreitier" }
  }

  data = {
    (each.value) = file("${path.module}/manifests/dashboards/${each.value}")
  }
}
