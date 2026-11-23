# Policy Reporter (kyverno/policy-reporter): reads the PolicyReports of Kyverno, serves a UI and Prometheus
# metrics. UI internal (VPN) at policy-reporter.<internal_domain>, login via Keycloak (client policy-reporter,
# restricted to infrastruktur_SG there). Grafana dashboards via the sidecar. See docs/kyverno.md.

locals {
  fqdn          = "policy-reporter.${var.internal_domain}"
  oidc_secret   = "policy-reporter-oidc"
  discovery_url = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}/.well-known/openid-configuration"
  eso_api       = "external-secrets.io/v1"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

# Keys as the UI expects them in ui.openIDConnect.secretRef (discoveryUrl, clientId, clientSecret)
resource "kubernetes_manifest" "oidc" {
  manifest = {
    apiVersion = local.eso_api
    kind       = "ExternalSecret"
    metadata   = { name = local.oidc_secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.oidc_secret
        creationPolicy = "Owner"
        template = {
          data = {
            discoveryUrl = local.discovery_url
            clientId     = "{{ .client_id }}"
            clientSecret = "{{ .client_secret }}"
          }
        }
      }
      data = [
        { secretKey = "client_id", remoteRef = { key = var.oidc_kv_name, property = "client_id" } },
        { secretKey = "client_secret", remoteRef = { key = var.oidc_kv_name, property = "client_secret" } },
      ]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "helm_release" "this" {
  name       = "policy-reporter"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "oci://ghcr.io/kyverno/charts"
  chart      = "policy-reporter"
  version    = var.chart_version

  values = [yamlencode({
    resources = var.resources.core

    metrics = { enabled = true }

    # JSON logs (core, UI, Kyverno plugin), parsed by Alloy (basement config/alloy/workload-logs.alloy).
    # client-go warnings stay klog text.
    logging = { encoding = "json" }

    ui = {
      enabled     = true
      resources   = var.resources.ui
      displayMode = "dark"
      logging     = { encoding = "json" }

      openIDConnect = {
        enabled     = true
        callbackUrl = "https://${local.fqdn}/callback"
        secretRef   = local.oidc_secret
        scopes      = ["openid", "profile", "email"]
        pkce        = true
      }

      ingress = {
        enabled   = true
        className = var.ingress_class
        hosts     = [{ host = local.fqdn, paths = [{ path = "/", pathType = "Prefix" }] }]
        # TLS ends at the internal Traefik (wildcard default certificate) – no tls section
      }
    }

    # Policy details (title, description, CEL) in the UI
    plugin = {
      kyverno = {
        enabled   = true
        resources = var.resources.kyverno_plugin
        logging   = { encoding = "json" }
      }
    }

    monitoring = {
      enabled        = var.monitoring_enabled
      serviceMonitor = { enabled = var.monitoring_enabled }
      grafana = {
        dashboards = { enabled = var.monitoring_enabled }
        # Folder via the Grafana sidecar's folderAnnotation (modules/monitoring)
        folder     = { annotation = "grafana_dashboard_folder", name = "Kyverno" }
        datasource = { label = "Prometheus", pluginId = "prometheus", pluginName = "Prometheus" }
      }
    }
  })]

  timeout = 600

  depends_on = [kubernetes_manifest.oidc]
}
