# Loki (grafana-community chart) as a single binary; chunks and index in Hetzner Object Storage (no request
# charges – decided over AWS S3/Garage), WAL on an hcloud volume. Retention by the compactor.
locals {
  loki_values = {
    deploymentMode = "SingleBinary"

    loki = {
      auth_enabled       = false
      analytics          = { reporting_enabled = false }
      commonConfig       = { replication_factor = 1 }
      podSecurityContext = { fsGroupChangePolicy = "OnRootMismatch" }

      storage = {
        type = "s3"
        bucketNames = {
          chunks = var.loki_s3.bucket
          ruler  = var.loki_s3.bucket
          admin  = var.loki_s3.bucket
        }
        s3 = {
          endpoint         = var.loki_s3.endpoint
          region           = var.loki_s3.region
          accessKeyId      = "$${S3_ACCESS_KEY}"
          secretAccessKey  = "$${S3_SECRET_KEY}"
          s3ForcePathStyle = true
          insecure         = false
        }
      }

      schemaConfig = {
        configs = [{
          from         = "2026-11-01"
          store        = "tsdb"
          object_store = "s3"
          schema       = "v13"
          index        = { prefix = "loki_index_", period = "24h" }
        }]
      }

      limits_config = {
        retention_period          = var.loki_retention
        allow_structured_metadata = true
        ingestion_rate_mb         = 10
        ingestion_burst_size_mb   = 25
        # Lines over max_line_size (default 256KB, e.g. JSON logs with long stack traces) are truncated instead of
        # being dropped as a whole (loki_discarded_samples_total{reason="line_too_long"})
        max_line_size          = "256KB"
        max_line_size_truncate = true
      }

      compactor = {
        retention_enabled    = true
        delete_request_store = "s3"
      }

      rulerConfig = {
        alertmanager_url       = local.alertmanager_url
        enable_alertmanager_v2 = true
      }
    }

    # S3 credentials, expanded into the config (${S3_*}); the chart passes -config.expand-env=true
    # loki-sc-rules (rules sidecar)
    sidecar = { resources = var.resources.loki_sidecar }

    singleBinary = {
      replicas    = 1
      persistence = { enabled = true, size = var.loki_pvc_size }
      resources   = var.resources.loki
      extraEnv = [
        { name = "S3_ACCESS_KEY", valueFrom = { secretKeyRef = { name = local.loki_s3_secret, key = "access_key" } } },
        { name = "S3_SECRET_KEY", valueFrom = { secretKeyRef = { name = local.loki_s3_secret, key = "secret_key" } } },
      ]
    }
    read    = { replicas = 0 }
    write   = { replicas = 0 }
    backend = { replicas = 0 }

    # API only (push, query, rules – Loki has no UI); internal, without login like Prometheus (prometheus.tf)
    ingress = {
      enabled          = true
      ingressClassName = var.ingress_class
      hosts            = [local.loki_fqdn]
    }
    gateway      = { enabled = false }
    chunksCache  = { enabled = false }
    resultsCache = { enabled = false }
    lokiCanary   = { enabled = false }
    test         = { enabled = false }

    monitoring = {
      dashboards     = { enabled = true }
      serviceMonitor = { enabled = true }
      rules          = { enabled = false }
    }
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.this["loki"].metadata[0].name
  repository = "oci://ghcr.io/grafana-community/helm-charts"
  chart      = "loki"
  version    = var.loki_version

  values = [yamlencode(local.loki_values)]

  timeout         = 600
  cleanup_on_fail = true
  atomic          = true

  # ServiceMonitor CRD from kube-prometheus-stack, S3 credentials from OpenBao
  depends_on = [helm_release.kube_prometheus_stack, kubernetes_manifest.loki_s3]
}
