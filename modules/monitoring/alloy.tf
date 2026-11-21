# Grafana k8s-monitoring (Alloy): pod logs, node journal and Kubernetes events → Loki; etcd metrics (RKE2
# serves them on 127.0.0.1:2381 of the etcd node) → Prometheus remote write. Node and Kubernetes metrics come
# from kube-prometheus-stack (node-exporter, kube-state-metrics, kubelet/cAdvisor).
locals {
  # GeoIP database (config/alloy/traefik-geoip.alloy): emptyDir filled by the init container, read-only in Alloy.
  # Second Helm values document (deep-merged); both branches are strings – a conditional must return the same type
  geoip_values_yaml = var.geoip_init == null ? "{}" : yamlencode({ collectors = { alloy-logs = {
    alloy = { mounts = { extra = [{ name = "geoip", mountPath = "/geoip", readOnly = true }] } }
    controller = {
      volumes = { extra = [{ name = "geoip", emptyDir = { sizeLimit = "64Mi" } }] }
      initContainers = [{
        name         = "geoip-db"
        image        = try(var.geoip_init.image, "")
        command      = ["sh", "-c", try(var.geoip_init.script, "")]
        volumeMounts = [{ name = "geoip", mountPath = "/geoip" }]
        resources = {
          requests = { cpu = "10m", memory = "32Mi" }
          limits   = { memory = "64Mi" }
        }
      }]
    }
  } } })

  k8s_monitoring_values = {
    cluster = { name = var.cluster_label }

    # Names are referenced from extraConfig as prometheus.remote_write.prometheus / loki.write.loki
    destinations = {
      prometheus = { type = "prometheus", url = "${local.prometheus_url}/api/v1/write" }
      loki       = { type = "loki", url = "${local.loki_url}/loki/api/v1/push" }
    }

    collectors = {
      alloy-logs = {
        presets             = ["filesystem-log-reader", "daemonset"]
        includeDestinations = ["prometheus"]
        extraConfig         = file("${path.module}/manifests/alloy-etcd-metrics.alloy")
        alloy = {
          extraEnv  = [{ name = "NODE_NAME", valueFrom = { fieldRef = { fieldPath = "spec.nodeName" } } }]
          resources = var.resources.alloy_logs
        }
        configReloader = { resources = var.resources.alloy_config_reloader }
        controller = {
          # Host network: reaches etcd on 127.0.0.1 of cp01
          hostNetwork = true
          dnsPolicy   = "ClusterFirstWithHostNet"
          tolerations = [{ operator = "Exists" }]
        }
      }
      alloy-singleton = {
        presets        = ["singleton"]
        alloy          = { resources = var.resources.alloy_singleton }
        configReloader = { resources = var.resources.alloy_config_reloader }
      }
    }

    clusterMetrics = { enabled = false }
    hostMetrics    = { enabled = false }

    clusterEvents = { enabled = true, collector = "alloy-singleton" }
    nodeLogs      = { enabled = true, collector = "alloy-logs" }
    podLogsViaLoki = {
      enabled                  = true
      collector                = "alloy-logs"
      extraLogProcessingStages = var.pod_log_processing_stages
    }

    telemetryServices = {
      "kube-state-metrics" = { deploy = false } # kube-prometheus-stack deploys it
      "node-exporter"      = { deploy = false }
    }

    selfReporting = { enabled = false }

    alloy-operator = { resources = var.resources.alloy_operator }
  }
}

resource "helm_release" "k8s_monitoring" {
  name       = "k8s-monitoring"
  namespace  = kubernetes_namespace_v1.this["alloy"].metadata[0].name
  repository = "oci://ghcr.io/grafana/helm-charts"
  chart      = "k8s-monitoring"
  version    = var.k8s_monitoring_version

  values = [yamlencode(local.k8s_monitoring_values), local.geoip_values_yaml]

  timeout         = 600
  cleanup_on_fail = true
  atomic          = true

  depends_on = [helm_release.kube_prometheus_stack, helm_release.loki]
}
