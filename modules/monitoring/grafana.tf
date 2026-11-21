# Grafana (grafana-community chart): internal (VPN) at grafana.<internal_domain>, login via Keycloak (client
# grafana, restricted to var.grafana_admin_group there → everyone who gets in is admin). Local admin
# (OpenBao k8s/prod/grafana) only as break-glass. SQLite on an hcloud volume; dashboards (sidecar) and
# datasources are provisioned.

locals {
  oidc_base = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}/protocol/openid-connect"

  grafana_values = {
    deploymentStrategy = { type = "Recreate" } # RWO volume
    # The first start (and major upgrades) migrates the SQLite database for longer than the chart's 60 s
    # liveness delay → the pod got killed mid-migration once (2026-11-16)
    livenessProbe = {
      httpGet             = { path = "/api/health", port = 3000 }
      initialDelaySeconds = 180
      timeoutSeconds      = 30
      failureThreshold    = 10
    }
    persistence = { enabled = true, size = var.grafana_pvc_size }
    resources   = var.resources.grafana

    ingress = {
      enabled          = true
      ingressClassName = var.ingress_class
      hosts            = [local.grafana_fqdn]
      # TLS ends at the internal Traefik (wildcard default certificate) – no tls section
    }

    admin = { existingSecret = local.grafana_admin_secret, userKey = "admin-user", passwordKey = "admin-password" }

    envValueFrom = {
      GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = { secretKeyRef = { name = local.grafana_oidc_secret, key = "client_secret" } }
    }

    "grafana.ini" = {
      server    = { root_url = "https://${local.grafana_fqdn}" }
      analytics = { reporting_enabled = false, check_for_updates = false }
      users     = { allow_sign_up = false }
      auth = {
        # Keycloak only redirects back with client_id + post_logout_redirect_uri (CLAUDE.md lesson)
        signout_redirect_url = "${local.oidc_base}/logout?client_id=grafana&post_logout_redirect_uri=${urlencode("https://${local.grafana_fqdn}/login")}"
      }
      "auth.generic_oauth" = {
        enabled                    = true
        name                       = "dreitier (Microsoft)"
        allow_sign_up              = true
        client_id                  = "grafana"
        scopes                     = "openid email profile groups"
        auth_url                   = "${local.oidc_base}/auth"
        token_url                  = "${local.oidc_base}/token"
        api_url                    = "${local.oidc_base}/userinfo"
        email_attribute_path       = "email"
        login_attribute_path       = "preferred_username"
        name_attribute_path        = "name"
        groups_attribute_path      = "groups"
        role_attribute_path        = "contains(groups[*], '${var.grafana_admin_group}') && 'Admin'"
        role_attribute_strict      = true
        allow_assign_grafana_admin = false
        use_pkce                   = true
        use_refresh_token          = true
      }
      smtp = {
        enabled         = true
        host            = "${var.smtp_host}:25"
        from_address    = var.mail_from
        from_name       = "Grafana"
        startTLS_policy = "NoStartTLS"
        skip_verify     = true
      }
    }

    # init container that chowns the SQLite volume
    initChownData = { resources = var.resources.grafana_init_chown }

    sidecar = {
      resources = var.resources.grafana_sidecar
      dashboards = {
        enabled          = true
        label            = "grafana_dashboard"
        labelValue       = "1"
        searchNamespace  = "ALL"
        folderAnnotation = "grafana_dashboard_folder"
        provider         = { foldersFromFilesStructure = true }
      }
    }

    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [
          {
            name      = "Prometheus"
            uid       = "prometheus"
            type      = "prometheus"
            url       = local.prometheus_url
            access    = "proxy"
            isDefault = true
            editable  = false
            # timeInterval = scrape interval → $__rate_interval spans at least 4 scrapes (2 min); Alloy on
            # other clusters scrapes at 30s too (alloy-agent)
            jsonData = { httpMethod = "POST", prometheusType = "Prometheus", timeInterval = "30s" }
          },
          {
            name     = "Loki"
            uid      = "loki"
            type     = "loki"
            url      = local.loki_url
            access   = "proxy"
            editable = false
          },
          {
            name     = "Alertmanager"
            uid      = "alertmanager"
            type     = "alertmanager"
            url      = local.alertmanager_url
            access   = "proxy"
            editable = false
            jsonData = { implementation = "prometheus", handleGrafanaManagedAlerts = false }
          },
        ]
      }
    }
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
  repository = "oci://ghcr.io/grafana-community/helm-charts"
  chart      = "grafana"
  version    = var.grafana_version

  values = [yamlencode(local.grafana_values)]

  timeout         = 600
  cleanup_on_fail = true
  atomic          = true

  depends_on = [kubernetes_manifest.grafana_admin, kubernetes_manifest.grafana_oidc]
}
