# Kyverno policy engine (installs the CRDs via its kyverno-api sub-chart). Policies live in the separate unit
# security/kyverno-policies (modules/kyverno-policies) – CRDs and CRs are never in the same unit.
# Kyverno >= 1.20 only knows the CEL policy types (policies.kyverno.io: ValidatingPolicy,
# ImageValidatingPolicy, MutatingPolicy, ...); ClusterPolicy/Policy are gone. See docs/kyverno.md.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

locals {
  service_monitor = { enabled = var.monitoring_enabled }
}

resource "helm_release" "this" {
  name       = "kyverno"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "oci://ghcr.io/kyverno/charts"
  chart      = "kyverno"
  version    = var.chart_version

  values = [yamlencode({
    crds = { install = true }

    config = {
      # Chart default excludes kube-system (and the kyverno namespace via excludeKyvernoNamespace).
      # Webhooks of the policies themselves use failurePolicy Ignore while in Audit (kyverno-policies).
      webhooks = {
        namespaceSelector = {
          matchExpressions = [{
            key      = "kubernetes.io/metadata.name"
            operator = "NotIn"
            values   = var.webhook_excluded_namespaces
          }]
        }
      }
    }

    admissionController = {
      # 2 replicas, preferred anti-affinity (chart default) – only 2 workers; >1 replica enables the PDB
      replicas       = var.admission_replicas
      container      = { resources = var.resources.admission_controller }
      serviceMonitor = local.service_monitor
    }
    backgroundController = {
      resources      = var.resources.background_controller
      serviceMonitor = local.service_monitor
    }
    cleanupController = {
      resources      = var.resources.cleanup_controller
      serviceMonitor = local.service_monitor
    }
    reportsController = {
      resources      = var.resources.reports_controller
      serviceMonitor = local.service_monitor
    }

    # Dashboard ConfigMap for the Grafana sidecar (label grafana_dashboard=1, searchNamespace ALL)
    grafana = { enabled = var.monitoring_enabled }

    prometheusRule = {
      enabled = var.monitoring_enabled
      spec = [{
        name = "kyverno.admission"
        rules = [
          {
            alert  = "KyvernoAdmissionHighLatency"
            expr   = "histogram_quantile(0.99, sum(rate(kyverno_admission_review_duration_seconds_bucket[5m])) by (le)) > 1"
            for    = "10m"
            labels = { severity = "warning" }
            annotations = {
              summary     = "Kyverno admission review p99 latency is elevated"
              description = "Admission review p99 latency is {{ $value | humanizeDuration }} (> 1s). Webhooks time out at 10s."
            }
          },
          {
            alert  = "KyvernoAdmissionCriticalLatency"
            expr   = "histogram_quantile(0.99, sum(rate(kyverno_admission_review_duration_seconds_bucket[5m])) by (le)) > 5"
            for    = "5m"
            labels = { severity = "critical" }
            annotations = {
              summary     = "Kyverno admission review p99 latency is critically high"
              description = "Admission review p99 latency is {{ $value | humanizeDuration }} (> 5s). Webhooks time out at 10s."
            }
          },
        ]
      }]
    }
  })]

  timeout = 600

  # Removing the release deletes the CRDs and with them every policy and PolicyReport
  lifecycle {
    prevent_destroy = true
  }
}
