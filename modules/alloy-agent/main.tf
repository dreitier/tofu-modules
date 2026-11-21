# Grafana k8s-monitoring (Alloy) for a cluster without its own Prometheus/Loki (today: Rancher's local k3s).
# Ships to the central Prometheus (remote write) and Loki of the prod cluster through their internal
# ingresses (internal Traefik, no login – docs/monitoring.md). Every series and log line gets
# cluster=<cluster_label> (destination clusterLabels, chart default).
#   logs:    pod logs, node journal, Kubernetes events
#   metrics: kubelet, cAdvisor, kube-state-metrics, node-exporter (deployed by the chart), annotated pods
#            (k8s.grafana.com/scrape, e.g. Traefik)
# Job labels as in kube-prometheus-stack (kubelet, kube-state-metrics, node-exporter) and metrics_path on the
# kubelet jobs, so its default dashboards and rules cover this cluster too; full metric sets instead of the
# chart's allow lists for the same reason.
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

  # The ServiceMonitors of kube-prometheus-stack set metrics_path; its kubelet rules/dashboards filter on it
  metrics_path_rule = <<-EOT
    rule {
      target_label = "metrics_path"
      replacement  = "%s"
    }
  EOT

  values = {
    cluster = { name = var.cluster_label }

    # Same interval as the central Prometheus (kube-prometheus-stack: 30s). The chart default 60s leaves a
    # single sample in Grafana's $__rate_interval window (1 min) → rate() returns nothing.
    global = { scrapeInterval = "30s" }

    destinations = {
      prometheus = { type = "prometheus", url = "${trimsuffix(var.prometheus_url, "/")}/api/v1/write" }
      loki       = { type = "loki", url = "${trimsuffix(var.loki_url, "/")}/loki/api/v1/push" }
    }

    collectors = {
      alloy-logs = {
        presets = ["filesystem-log-reader", "daemonset"]
        alloy   = { resources = var.resources.alloy_logs }
        controller = {
          tolerations = [{ operator = "Exists" }]
        }
      }
      alloy-singleton = {
        presets = ["singleton"]
        alloy   = { resources = var.resources.alloy_singleton }
      }
    }

    clusterMetrics = {
      enabled   = true
      collector = "alloy-singleton"
      kubelet = {
        jobLabel            = "kubelet"
        metricsTuning       = { useDefaultAllowList = false }
        extraDiscoveryRules = format(local.metrics_path_rule, "/metrics")
      }
      cadvisor = {
        jobLabel            = "kubelet"
        metricsTuning       = { useDefaultAllowList = false }
        extraDiscoveryRules = format(local.metrics_path_rule, "/metrics/cadvisor")
      }
      "kube-state-metrics" = {
        jobLabel      = "kube-state-metrics"
        metricsTuning = { useDefaultAllowList = false }
      }
    }

    hostMetrics = {
      enabled   = true
      collector = "alloy-singleton"
      linuxHosts = {
        enabled       = true
        jobLabel      = "node-exporter"
        metricsTuning = { useDefaultAllowList = false }
      }
    }

    clusterEvents = { enabled = true, collector = "alloy-singleton" }
    nodeLogs      = { enabled = true, collector = "alloy-logs" }
    podLogsViaLoki = {
      enabled                  = true
      collector                = "alloy-logs"
      extraLogProcessingStages = var.pod_log_processing_stages
    }

    # Pods/services with k8s.grafana.com/scrape=true (k3s' Traefik, HelmChartConfig on the Rancher VM)
    annotationAutodiscovery = { enabled = true, collector = "alloy-singleton" }

    telemetryServices = {
      "kube-state-metrics" = { deploy = true }
      "node-exporter"      = { deploy = true }
    }

    selfReporting = { enabled = false }
  }
}

resource "helm_release" "k8s_monitoring" {
  name             = "k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  repository       = "oci://ghcr.io/grafana/helm-charts"
  chart            = "k8s-monitoring"
  version          = var.k8s_monitoring_version

  values = [yamlencode(local.values), local.geoip_values_yaml]

  timeout         = 600
  cleanup_on_fail = true
  atomic          = true
}
