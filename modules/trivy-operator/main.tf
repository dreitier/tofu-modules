# Trivy Operator: continuous in-cluster scans – vulnerabilities and SBOMs of the running images, config audit,
# exposed secrets, RBAC and infra assessment, compliance reports (RKE2 CIS, NSA, PSS). Results are CRs
# (VulnerabilityReport, ConfigAuditReport, ...) per workload plus Prometheus metrics. Step 3 of the cluster
# hardening (docs/trivy-operator.md).
#
# Built-in Trivy server (ClientServer mode): one vulnerability DB in the server's volume instead of a DB
# download per scan job. Scan jobs run in this namespace (excluded from the Kyverno policies).
#
# CRDs come from the chart's crds/ directory: Helm installs them on the first install only – on chart
# upgrades apply them by hand (docs/trivy-operator.md, Renovate label crd-upgrade).

locals {
  # chart defaults (kubeadm layout) + RKE2's agent directory
  node_collector_paths = [
    { name = "var-lib-etcd", path = "/var/lib/etcd" },
    { name = "var-lib-kubelet", path = "/var/lib/kubelet" },
    { name = "var-lib-kube-scheduler", path = "/var/lib/kube-scheduler" },
    { name = "var-lib-kube-controller-manager", path = "/var/lib/kube-controller-manager" },
    { name = "etc-systemd", path = "/etc/systemd" },
    { name = "lib-systemd", path = "/lib/systemd" },
    { name = "etc-kubernetes", path = "/etc/kubernetes" },
    { name = "etc-cni-netd", path = "/etc/cni/net.d" },
    { name = "var-lib-rancher-rke2-agent", path = "/var/lib/rancher/rke2/agent" },
  ]
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  name       = "trivy-operator"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://aquasecurity.github.io/helm-charts/"
  chart      = "trivy-operator"
  version    = var.chart_version

  values = [yamlencode({
    excludeNamespaces = join(",", var.excluded_namespaces)

    operator = {
      builtInTrivyServer      = true
      scanJobsConcurrentLimit = var.scan_jobs_concurrent_limit
      # metrics per finding (severity counts per image/workload) – no per-CVE series (cardinality)
      metricsFindingsEnabled = true
      metricsVulnIdEnabled   = false
      # every report is POSTed here (SbomReports → Dependency-Track); deleted reports are not sent
      webhookBroadcastURL       = var.webhook_url == null ? "" : var.webhook_url
      webhookSendDeletedReports = false
    }

    trivy = {
      storageClassName = var.storage_class
      storageSize      = var.storage_size
      resources        = var.resources.scan_job
      server           = { resources = var.resources.trivy_server }
    }

    resources = var.resources.operator

    serviceMonitor = { enabled = var.monitoring_enabled }

    compliance = {
      specs = var.compliance_specs
    }

    # Node collector (CIS node checks, one job per node): must also run on the control plane node (RKE2 taints
    # node-role.kubernetes.io/control-plane:NoSchedule and etcd:NoExecute) → tolerate everything. RKE2 keeps
    # its pod manifests, kubeconfigs and certificates in /var/lib/rancher/rke2/agent, which the chart's
    # default (kubeadm) mounts don't cover. The lists replace the chart defaults, so they are repeated here.
    nodeCollector = {
      tolerations  = [{ operator = "Exists" }]
      volumes      = [for v in local.node_collector_paths : { name = v.name, hostPath = { path = v.path } }]
      volumeMounts = [for v in local.node_collector_paths : { name = v.name, mountPath = v.path, readOnly = true }]
    }
  })]

  timeout = 600

  # Removing the release would delete the CRDs and with them every report
  lifecycle {
    prevent_destroy = true
  }
}
