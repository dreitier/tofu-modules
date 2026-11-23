# Actions Runner Controller (gha-runner-scale-set-controller) – installs the CRDs (AutoscalingRunnerSet, …), so
# the runner scale sets are a separate unit (platform/arc-runners). The controller only watches the runners'
# namespace (Role instead of ClusterRole), which is created here too. docs/ci-deploy.md

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
    # the listener pods' spec comes from the controller – warn/audit only (Kyverno reports as well)
    labels = { "pod-security.kubernetes.io/warn" = "restricted", "pod-security.kubernetes.io/audit" = "restricted" }
  }
}

# Namespace of the runner scale sets (platform/arc-runners): created here because the controller, watching only
# this namespace, puts its Role/RoleBinding into it at install time
resource "kubernetes_namespace_v1" "runners" {
  metadata {
    name   = var.watch_namespace
    labels = { "pod-security.kubernetes.io/enforce" = "restricted" }
  }
}

resource "helm_release" "this" {
  name       = "arc"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.chart_version

  values = [yamlencode({
    fullnameOverride = var.controller_name
    serviceAccount   = { create = true, name = var.controller_name }

    flags = {
      logLevel = "info"
      # JSON instead of zap's tab-separated console format, parsed by Alloy (basement config/alloy/workload-logs.alloy)
      logFormat = "json"
      # only the runners' namespace – the scale sets name this service account explicitly
      watchSingleNamespace = var.watch_namespace
    }

    podSecurityContext = { runAsNonRoot = true, seccompProfile = { type = "RuntimeDefault" } }
    securityContext = {
      allowPrivilegeEscalation = false
      readOnlyRootFilesystem   = true
      capabilities             = { drop = ["ALL"] }
    }
    resources = var.resources
  })]

  depends_on = [kubernetes_namespace_v1.runners]
}
