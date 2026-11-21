# kube-prometheus-stack: Prometheus (hcloud volume), Alertmanager (mail via platform/mail-relay), operator,
# kube-state-metrics, node-exporter, the chart's default alert rules and dashboards (picked up by Grafana's
# sidecar). Prometheus and Alertmanager on internal ingresses (prometheus./alertmanager.<internal domain>)
# WITHOUT login – decided 2026-11-16: every VPN user (vpn-access_SG) can reach them, read metrics and set
# silences. Protection would be ForwardAuth via oauth2-proxy (Keycloak, infrastruktur_SG).
# RKE2 binds controller-manager, scheduler and etcd to localhost → not scraped by the chart; etcd comes from
# Alloy on the node (manifests/alloy-etcd-metrics.alloy, job="etcd").

locals {
  # Static blackbox jobs, one per module; every series also gets cluster=<cluster_label>
  blackbox_jobs = [
    for module, targets in var.blackbox_targets : {
      job_name        = "blackbox-${module}"
      metrics_path    = "/probe"
      scrape_interval = "60s"
      scrape_timeout  = "30s"
      params          = { module = [module] }
      static_configs  = [{ targets = targets }]
      relabel_configs = [
        { source_labels = ["__address__"], target_label = "__param_target" },
        { source_labels = ["__param_target"], target_label = "instance" },
        { target_label = "__address__", replacement = "${local.blackbox_fullname}.${var.namespaces.monitoring}.svc:${local.blackbox_port}" },
        { target_label = "cluster", replacement = var.cluster_label },
      ]
    }
  ]

  alertmanager_config = {
    global = {
      resolve_timeout  = "5m"
      smtp_smarthost   = "${var.smtp_host}:25"
      smtp_from        = var.mail_from
      smtp_require_tls = false # in-cluster relay without TLS; it forwards with STARTTLS
      smtp_hello       = "alertmanager"
    }
    route = {
      group_by        = ["alertname", "namespace", "job"]
      group_wait      = "30s"
      group_interval  = "5m"
      repeat_interval = "12h"
      receiver        = "mail"
      routes = [
        # Watchdog (always firing) → external heartbeat: re-sent every minute; if it stops, the heartbeat
        # service raises the alarm (Prometheus/Alertmanager/cluster/egress dead)
        {
          receiver        = var.heartbeat == null ? "null" : "heartbeat"
          matchers        = ["alertname=\"Watchdog\""]
          group_wait      = "0s"
          group_interval  = "1m"
          repeat_interval = "1m"
        },
        { receiver = "null", matchers = ["alertname=\"InfoInhibitor\""] },
        { receiver = "null", matchers = ["severity=~\"info|none\""] },
      ]
    }
    receivers = concat([
      { name = "mail", email_configs = [{ to = var.mail_to, send_resolved = true }] },
      { name = "null" },
      ], var.heartbeat == null ? [] : [{
        name = "heartbeat"
        # Ping URL from a mounted Secret (alertmanagerSpec.secrets) – never in the Helm values
        webhook_configs = [{ url_file = "/etc/alertmanager/secrets/${local.heartbeat_secret}/ping_url", send_resolved = false }]
    }])
    inhibit_rules = [
      # The chart's defaults: critical silences warning/info of the same alert, InfoInhibitor silences info
      { source_matchers = ["severity=\"critical\""], target_matchers = ["severity=~\"warning|info\""], equal = ["namespace", "alertname"] },
      { source_matchers = ["severity=\"warning\""], target_matchers = ["severity=\"info\""], equal = ["namespace", "alertname"] },
      { source_matchers = ["alertname=\"InfoInhibitor\""], target_matchers = ["severity=\"info\""], equal = ["namespace"] },
      { source_matchers = ["alertname=\"BlackboxProbeFailed\""], target_matchers = ["alertname=\"CertificateExpiresSoon\""], equal = ["instance"] },
    ]
  }

  kps_values = {
    fullnameOverride = local.kps_fullname

    crds = { enabled = true }

    # Separate Grafana release (grafana.tf); the chart still ships its dashboards as ConfigMaps
    grafana = {
      enabled                  = false
      forceDeployDashboards    = true
      defaultDashboardsEnabled = true
      # Show the cluster variable in the default dashboards: the Rancher cluster ships into this Prometheus
      # too (kubernetes/rancher/monitoring, cluster=rancher)
      sidecar = { dashboards = { multicluster = { global = { enabled = true }, etcd = { enabled = true } } } }
    }

    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeProxy             = { enabled = false }
    kubeEtcd              = { enabled = false } # Alloy (job="etcd")
    windowsMonitoring     = { enabled = false }

    defaultRules = {
      create = true
      rules = {
        kubeControllerManager  = false
        kubeSchedulerAlerting  = false
        kubeSchedulerRecording = false
        kubeProxy              = false
        windows                = false
      }
    }

    "kube-state-metrics" = { resources = var.resources.kube_state_metrics }
    "prometheus-node-exporter" = {
      resources = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "64Mi" } }
      # Also on the control-plane node (cp01)
      tolerations = [{ operator = "Exists" }]
    }

    prometheusOperator = {
      resources = var.resources.prometheus_operator
      # config-reloader (+ init) in the Prometheus and Alertmanager pods
      prometheusConfigReloader = { resources = var.resources.prometheus_config_reloader }
    }

    # Own alert rules (manifests/rules/*.yml, Prometheus rule-file format) as PrometheusRules of this release –
    # not as kubernetes_manifest: that needs the CRD at plan time, which only this release installs
    additionalPrometheusRulesMap = {
      for f in fileset("${path.module}/manifests/rules", "*.yml") :
      "rules-${trimsuffix(f, ".yml")}" => yamldecode(file("${path.module}/manifests/rules/${f}"))
    }

    alertmanager = {
      config = local.alertmanager_config
      # TLS ends at the internal Traefik (wildcard default certificate) – no tls section
      ingress = { enabled = true, ingressClassName = var.ingress_class, hosts = [local.alertmanager_fqdn], paths = ["/"], pathType = "Prefix" }
      alertmanagerSpec = {
        externalUrl = "https://${local.alertmanager_fqdn}"
        resources   = var.resources.alertmanager
        secrets     = var.heartbeat == null ? [] : [local.heartbeat_secret]
        storage = {
          volumeClaimTemplate = { spec = { resources = { requests = { storage = var.alertmanager_pvc_size } } } }
        }
      }
    }

    prometheus = {
      ingress = { enabled = true, ingressClassName = var.ingress_class, hosts = [local.prometheus_fqdn], paths = ["/"], pathType = "Prefix" }
      prometheusSpec = {
        externalUrl    = "https://${local.prometheus_fqdn}"
        externalLabels = { cluster = var.cluster_label }
        # Store the cluster label on the series (ServiceMonitors, PodMonitors, Probes); static jobs: blackbox_jobs
        scrapeClasses = [{
          name        = "default"
          default     = true
          relabelings = [{ targetLabel = "cluster", replacement = var.cluster_label }]
        }]
        retention     = var.prometheus_retention
        retentionSize = var.prometheus_retention_size
        # Alloy writes the etcd metrics via remote write
        enableRemoteWriteReceiver = true
        # All ServiceMonitors/PodMonitors/Probes/rules of the cluster, not only the chart's own
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        probeSelectorNilUsesHelmValues          = false
        ruleSelectorNilUsesHelmValues           = false
        scrapeConfigSelectorNilUsesHelmValues   = false
        additionalScrapeConfigsSecret = {
          enabled = true
          name    = kubernetes_secret_v1.additional_scrape_configs.metadata[0].name
          key     = "prometheus-additional.yaml"
        }
        resources = var.resources.prometheus
        storageSpec = {
          volumeClaimTemplate = { spec = { resources = { requests = { storage = var.prometheus_pvc_size } } } }
        }
      }
    }
  }
}

resource "kubernetes_secret_v1" "additional_scrape_configs" {
  metadata {
    name      = "additional-scrape-configs"
    namespace = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
  }
  data = {
    "prometheus-additional.yaml" = yamlencode(local.blackbox_jobs)
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
  repository = "oci://ghcr.io/prometheus-community/charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  values = [yamlencode(local.kps_values)]

  timeout         = 900
  cleanup_on_fail = true
  atomic          = true

  # Alertmanager mounts the heartbeat Secret – it must exist before the pod starts
  depends_on = [kubernetes_manifest.heartbeat]
}

resource "helm_release" "blackbox_exporter" {
  name       = "blackbox-exporter"
  namespace  = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
  repository = "oci://ghcr.io/prometheus-community/charts"
  chart      = "prometheus-blackbox-exporter"
  version    = var.blackbox_exporter_version

  values = [yamlencode({
    fullnameOverride = local.blackbox_fullname
    service          = { port = local.blackbox_port }
    config           = { modules = yamldecode(file("${path.module}/manifests/blackbox-modules.yaml")) }
    resources        = var.resources.blackbox_exporter
  })]

  cleanup_on_fail = true
  atomic          = true
}
