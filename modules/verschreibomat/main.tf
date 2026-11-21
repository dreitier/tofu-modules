# verschreibomat (dreitier/verschreibomat): timesheets for customers from Moco time entries. Spring Boot,
# VPN only (internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak for every user of
# the realm (no access group – each user only sees their own data in the application).
# Secrets are never environment variables: one ExternalSecret renders them into secrets.yaml, mounted
# read-only at /etc/verschreibomat (the image's default VERSCHREIBOMAT_SECRETS_FILE):
#   <keys_kv_name>   encryption keys of the users' Moco API keys (scripts/verschreibomat-keys.sh, write once)
#   <db_kv_name>     password of the database role (config/openbao-base, data/postgresql)
#   <oidc_kv_name>   Keycloak client secret (config/keycloak, client verschreibomat)
# The image is a private GHCR package → pull secret from <pull_kv_name> (written by hand, docs/verschreibomat.md).
# Actuator (health, prometheus) listens on its own port (management, 8081), which the Ingress doesn't route;
# the application permits /actuator/prometheus there without login. Scraped by a ServiceMonitor.
# Spring reads the secrets file only at startup: after a rotation restart the Deployment.

locals {
  name        = "verschreibomat"
  secret      = "verschreibomat-secrets"
  pull_secret = "ghcr-pull"
  uid         = 10001 # user of the image
  oidc_issuer = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}"
  labels      = { "app.kubernetes.io/name" = local.name }
  # actuator port; not behind the Ingress
  management_port = 8081

  # YAML of the secrets file; ESO fills in the values (Go templates inside double-quoted YAML strings –
  # fine for the generated values: alphanumeric passwords/client secrets, Base64 keys).
  secrets_yaml = yamlencode({
    spring = {
      datasource = { password = "{{ .db_password }}" }
      security = {
        oauth2 = {
          client = {
            registration = {
              keycloak = { "client-secret" = "{{ .oidc_client_secret }}" }
            }
          }
        }
      }
    }
    verschreibomat = {
      encryption = {
        "active-key" = var.encryption_active_key
        keys         = { for id in var.encryption_key_ids : id => "{{ .encryption_key_${id} }}" }
      }
    }
  })
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "secrets" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = local.secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.secret
        creationPolicy = "Owner"
        template       = { data = { "secrets.yaml" = local.secrets_yaml } }
      }
      data = concat(
        [
          { secretKey = "db_password", remoteRef = { key = var.db_kv_name, property = "user_${var.db_user}_pass" } },
          { secretKey = "oidc_client_secret", remoteRef = { key = var.oidc_kv_name, property = "client_secret" } },
        ],
        [for id in var.encryption_key_ids : {
          secretKey = "encryption_key_${id}", remoteRef = { key = var.keys_kv_name, property = "encryption_key_${id}" }
        }],
      )
    }
  }

  lifecycle {
    precondition {
      condition     = contains(var.encryption_key_ids, var.encryption_active_key)
      error_message = "encryption_active_key must be one of encryption_key_ids."
    }
  }
}

resource "kubernetes_manifest" "pull_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = local.pull_secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.pull_secret
        creationPolicy = "Owner"
        template = {
          type = "kubernetes.io/dockerconfigjson"
          data = {
            ".dockerconfigjson" = "{\"auths\":{\"ghcr.io\":{\"auth\":\"{{ printf \"%s:%s\" .username .token | b64enc }}\"}}}"
          }
        }
      }
      data = [
        { secretKey = "username", remoteRef = { key = var.pull_kv_name, property = "username" } },
        { secretKey = "token", remoteRef = { key = var.pull_kv_name, property = "token" } },
      ]
    }
  }
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    replicas = 1
    selector {
      match_labels = local.labels
    }
    # one instance at a time: Liquibase migrates on startup
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        image_pull_secrets {
          name = local.pull_secret
        }
        automount_service_account_token = false
        enable_service_links            = false

        security_context {
          run_as_non_root = true
          run_as_user     = local.uid
          run_as_group    = local.uid
          fs_group        = local.uid # makes the secrets file readable (mode 0440)
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = local.name
          image = var.image

          port {
            name           = "http"
            container_port = 8080
          }
          port {
            name           = "management"
            container_port = local.management_port
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://${var.db_host}:5432/${var.db_name}"
          }
          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = var.db_user
          }
          env {
            name  = "SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_KEYCLOAK_ISSUER_URI"
            value = local.oidc_issuer
          }
          env {
            name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_KEYCLOAK_CLIENT_ID"
            value = var.oidc_client_id
          }
          env {
            name  = "VERSCHREIBOMAT_MOCO_BASE_URL"
            value = var.moco_base_url
          }
          # Replaces the image's JAVA_TOOL_OPTIONS (keep its two options). preferIPv4Stack: the JVM's IPv6 lookup
          # failed in the pod (UnresolvedAddressException for dreitier.mocoapp.com while glibc/getent resolved
          # it; 2026-11-17) – the pod network is IPv4 only.
          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = "-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError -Djava.net.preferIPv4Stack=true"
          }
          # actuator on its own port: /actuator/prometheus without login, never reachable through the Ingress
          env {
            name  = "MANAGEMENT_SERVER_PORT"
            value = tostring(local.management_port)
          }
          # probe groups liveness/readiness (Spring Boot enables them on Kubernetes anyway)
          env {
            name  = "MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED"
            value = "true"
          }
          # TLS ends at Traefik: take scheme and host from X-Forwarded-* (redirect URI https://<hostname>/…)
          env {
            name  = "SERVER_FORWARD_HEADERS_STRATEGY"
            value = "native"
          }

          volume_mount {
            name       = "secrets"
            mount_path = "/etc/verschreibomat"
            read_only  = true
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          security_context {
            # the provider sends runAsNonRoot: false for an unset container field, which overrides the pod
            # level (Kyverno require-run-as-nonroot) – set it explicitly
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = var.resources.requests
            limits   = var.resources.limits
          }

          # actuator on the management port, no login
          startup_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = "management"
            }
            period_seconds    = 5
            failure_threshold = 36 # 3 minutes (Liquibase on the first start)
          }
          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = "management"
            }
            period_seconds = 20
          }
          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = "management"
            }
            period_seconds = 10
          }
        }

        volume {
          name = "secrets"
          secret {
            secret_name  = local.secret
            default_mode = "0440"
          }
        }
        volume {
          name = "tmp"
          empty_dir {
            size_limit = "64Mi"
          }
        }
      }
    }
  }

  # the ExternalSecrets must have created both secrets before the pod starts
  depends_on = [kubernetes_manifest.secrets, kubernetes_manifest.pull_secret]
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
  }
  spec {
    selector = local.labels
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
    # for the ServiceMonitor only; the Ingress uses port http
    port {
      name        = "management"
      port        = local.management_port
      target_port = "management"
    }
  }
}

# Grafana dashboard: the sidecar of platform/monitoring picks up ConfigMaps with grafana_dashboard=1 in every
# namespace (folder from the annotation). Alerts: modules/monitoring/manifests/rules/dreitier.yml, group verschreibomat.
resource "kubernetes_config_map_v1" "dashboard" {
  count = var.monitoring_enabled ? 1 : 0

  metadata {
    name        = "${local.name}-dashboard"
    namespace   = kubernetes_namespace_v1.this.metadata[0].name
    labels      = merge(local.labels, { grafana_dashboard = "1" })
    annotations = { grafana_dashboard_folder = "Apps" }
  }
  data = {
    "verschreibomat.json" = file("${path.module}/dashboards/verschreibomat.json")
  }
}

# Spring Boot metrics (Micrometer, /actuator/prometheus) – needs the Prometheus Operator CRDs at plan time
resource "kubernetes_manifest" "service_monitor" {
  count = var.monitoring_enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata   = { name = local.name, namespace = kubernetes_namespace_v1.this.metadata[0].name, labels = local.labels }
    spec = {
      selector = { matchLabels = local.labels }
      endpoints = [{
        port          = "management"
        path          = "/actuator/prometheus"
        interval      = "30s"
        scrapeTimeout = "10s"
      }]
    }
  }
}

# TLS ends at the internal Traefik (wildcard default certificate) – no tls section
resource "kubernetes_ingress_v1" "this" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = var.hostname
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.this.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}
