# NetBird (combined netbird-server: management, signal, relay over WebSocket, embedded IdP/Dex) + dashboard,
# own manifests (docs/netbird.md). Public at https://<domain> via the public Traefik:
#   gRPC (h2c)  /management.ManagementService/, /signalexchange.SignalExchange/ → Service <name>-grpc
#   HTTP/1.1    /api, /oauth2, /relay, /ws-proxy                                → Service <name>-http
#   /                                                                           → dashboard
# STUN runs on the gateway (coturn – Hetzner LBs can't do UDP) → server.stuns, the local STUN is off.
# Stores in PostgreSQL (CNPG, databases netbird / netbird_events / netbird_idp). config.yaml with all
# secrets is rendered by an ExternalSecret from OpenBao (scripts/netbird-secrets.sh, config/openbao-base).
# Login: embedded IdP with Keycloak as connector – added once in the dashboard, then localAuthDisabled.

locals {
  base_url = "https://${var.domain}"
  dsn = {
    for k, db in { store = "netbird", events = "netbird_events", idp = "netbird_idp" } :
    k => "host=${var.db_host} port=5432 user=${var.db_user} password={{ .db_password }} dbname=${db} sslmode=require"
  }

  config = {
    server = {
      listenAddress      = ":80" # TLS ends at Traefik
      exposedAddress     = "${local.base_url}:443"
      metricsPort        = 9090
      healthcheckAddress = ":9000"
      logLevel           = var.log_level
      logFile            = "console"
      authSecret         = "{{ .relay_auth_secret }}"
      dataDir            = "/var/lib/netbird/"
      stuns              = [for s in var.stun_uris : { uri = s }]

      disableAnonymousMetrics = true

      auth = {
        issuer                          = "${local.base_url}/oauth2"
        localAuthDisabled               = var.local_auth_disabled
        signKeyRefreshEnabled           = true
        sessionCookieEncryptionKey      = "{{ .idp_cookie_key }}"
        dashboardRedirectURIs           = ["${local.base_url}/nb-auth", "${local.base_url}/nb-silent-auth"]
        cliRedirectURIs                 = ["http://localhost:53000/"]
        dashboardPostLogoutRedirectURIs = ["${local.base_url}/"]
        # Dex expects a bcrypt hash here, not the password (plain password stays in OpenBao for the login)
        owner = { email = var.owner_email, password = "{{ .owner_password_hash }}" }
      }

      store         = { engine = "postgres", dsn = local.dsn.store, encryptionKey = "{{ .store_encryption_key }}" }
      activityStore = { engine = "postgres", dsn = local.dsn.events }
      authStore     = { engine = "postgres", dsn = local.dsn.idp }

      # Traefik (pod network) in front – real client IPs from X-Forwarded-For
      # Peers whose X-Forwarded-For is trusted – default would be 0.0.0.0/0 (log warning)
      reverseProxy = { trustedHTTPProxies = var.trusted_proxies, trustedPeers = var.trusted_peers }
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "config" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = "netbird-config", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = "netbird-config"
        creationPolicy = "Owner"
        template       = { data = { "config.yaml" = yamlencode(local.config) } }
      }
      dataFrom = [{ extract = { key = var.secrets_kv_name } }]
      data = [
        { secretKey = "db_password", remoteRef = { key = var.db_kv_name, property = var.db_kv_property } },
      ]
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "data" {
  metadata {
    name      = "netbird-data"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
    resources {
      requests = { storage = "1Gi" }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "server" {
  metadata {
    name      = "netbird-server"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = { "app.kubernetes.io/name" = "netbird-server" }
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate" # RWO data volume
    }
    selector {
      match_labels = { "app.kubernetes.io/name" = "netbird-server" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "netbird-server" }
        # Restart on config changes (the Secret is rendered by ESO; its hash isn't known to Tofu)
        annotations = { "netbird.dreitier.com/config" = sha256(yamlencode(local.config)) }
      }
      spec {
        container {
          name  = "netbird-server"
          image = var.server_image
          args  = var.server_args

          port {
            name           = "http"
            container_port = 80
          }
          port {
            name           = "metrics"
            container_port = 9090
          }
          port {
            name           = "health"
            container_port = 9000
          }

          readiness_probe {
            tcp_socket {
              port = "http"
            }
            period_seconds = 10
          }
          liveness_probe {
            tcp_socket {
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }

          resources {
            requests = var.resources.server.requests
            limits   = var.resources.server.limits
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/netbird"
            read_only  = true
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/netbird"
          }
        }
        volume {
          name = "config"
          secret {
            secret_name = "netbird-config"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.config]
}

resource "kubernetes_deployment_v1" "dashboard" {
  metadata {
    name      = "netbird-dashboard"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = { "app.kubernetes.io/name" = "netbird-dashboard" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { "app.kubernetes.io/name" = "netbird-dashboard" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "netbird-dashboard" }
      }
      spec {
        container {
          name  = "dashboard"
          image = var.dashboard_image

          dynamic "env" {
            for_each = {
              NETBIRD_MGMT_API_ENDPOINT      = local.base_url
              NETBIRD_MGMT_GRPC_API_ENDPOINT = local.base_url
              AUTH_AUTHORITY                 = "${local.base_url}/oauth2"
              AUTH_CLIENT_ID                 = "netbird-dashboard"
              AUTH_AUDIENCE                  = "netbird-dashboard"
              AUTH_CLIENT_SECRET             = ""
              AUTH_SUPPORTED_SCOPES          = "openid profile email groups"
              AUTH_REDIRECT_URI              = "/nb-auth"
              AUTH_SILENT_REDIRECT_URI       = "/nb-silent-auth"
              USE_AUTH0                      = "false"
              LETSENCRYPT_DOMAIN             = "none" # TLS at Traefik
              NGINX_SSL_PORT                 = "443"
            }
            content {
              name  = env.key
              value = env.value
            }
          }

          port {
            name           = "http"
            container_port = 80
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          resources {
            requests = var.resources.dashboard.requests
            limits   = var.resources.dashboard.limits
          }
        }
      }
    }
  }
}

# Same pod, two Services: Traefik speaks h2c to the gRPC paths and HTTP/1.1 (WebSocket) to the rest
resource "kubernetes_service_v1" "server" {
  for_each = { http = "http", grpc = "h2c" }

  metadata {
    name        = "netbird-server-${each.key}"
    namespace   = kubernetes_namespace_v1.this.metadata[0].name
    annotations = each.value == "h2c" ? { "traefik.ingress.kubernetes.io/service.serversscheme" = "h2c" } : {}
  }
  spec {
    selector = { "app.kubernetes.io/name" = "netbird-server" }
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_service_v1" "dashboard" {
  metadata {
    name      = "netbird-dashboard"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    selector = { "app.kubernetes.io/name" = "netbird-dashboard" }
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name        = "netbird"
    namespace   = kubernetes_namespace_v1.this.metadata[0].name
    annotations = { "cert-manager.io/cluster-issuer" = var.cluster_issuer }
  }
  spec {
    ingress_class_name = var.ingress_class
    tls {
      hosts       = [var.domain]
      secret_name = "netbird-tls"
    }
    rule {
      host = var.domain
      http {
        dynamic "path" {
          for_each = {
            "/management.ManagementService/"  = "netbird-server-grpc"
            "/signalexchange.SignalExchange/" = "netbird-server-grpc"
            "/api"                            = "netbird-server-http"
            "/oauth2"                         = "netbird-server-http"
            "/relay"                          = "netbird-server-http"
            "/ws-proxy"                       = "netbird-server-http"
            "/"                               = "netbird-dashboard"
          }
          content {
            path      = path.key
            path_type = "Prefix"
            backend {
              service {
                name = path.value
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

  depends_on = [kubernetes_service_v1.server, kubernetes_service_v1.dashboard]
}
