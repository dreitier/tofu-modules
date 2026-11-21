# Dependency-Track 5 (api-server monolith + frontend), PostgreSQL in the CNPG cluster (data/postgresql).
#
# - UI and full API internal (VPN) at <internal_hostname>; login via Keycloak (public client, PKCE –
#   the SPA gets the token, the api-server validates it against the issuer). Access restricted to
#   infrastruktur_SG in Keycloak; OIDC users are provisioned and synced to teams by the groups claim.
# - Public (public Traefik, Let's Encrypt): ONLY the BOM upload API (/api/v1/bom…) and /api/version at
#   <public_hostname>, so GitHub Actions can push SBOMs with a team API key. Everything else answers 404
#   there.
#
# Secrets (ExternalSecrets from OpenBao, never env vars – the chart mounts them as files):
#   <db_kv_name>   password of the role (config/openbao-base, data/postgresql)
#   <kek_kv_name>  key encryption key of DT's secret management (scripts/dependency-track-kek.sh)
# See docs/dependency-track.md.

locals {
  oidc_issuer   = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}"
  db_secret     = "dependency-track-db"
  kek_secret    = "dependency-track-kek"
  public_tls    = "dependency-track-public-tls"
  eso_api       = "external-secrets.io/v1"
  release_name  = "dependency-track"
  api_service   = "${local.release_name}-api-server" # chart naming (monolith topology)
  api_port_name = "web"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "db" {
  manifest = {
    apiVersion = local.eso_api
    kind       = "ExternalSecret"
    metadata   = { name = local.db_secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.db_secret
        creationPolicy = "Owner"
        template       = { data = { username = var.db_user, password = "{{ .password }}" } }
      }
      data = [{ secretKey = "password", remoteRef = { key = var.db_kv_name, property = "user_${var.db_user}_pass" } }]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

# Losing the KEK makes every secret DT stores in the database (e.g. notification credentials) unreadable
resource "kubernetes_manifest" "kek" {
  manifest = {
    apiVersion = local.eso_api
    kind       = "ExternalSecret"
    metadata   = { name = local.kek_secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.kek_secret, creationPolicy = "Owner" }
      data            = [{ secretKey = "kek", remoteRef = { key = var.kek_kv_name, property = "kek" } }]
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
  name       = local.release_name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://dependencytrack.github.io/helm-charts"
  chart      = "dependency-track"
  version    = var.chart_version

  values = [yamlencode({
    database = {
      jdbcUrl        = "jdbc:postgresql://${var.db_host}:5432/${var.db_name}?reWriteBatchedInserts=true"
      existingSecret = { name = local.db_secret, usernameKey = "username", passwordKey = "password" }
    }

    secretManagement = {
      provider = "database"
      database = { kek = { mode = "config", existingSecret = { name = local.kek_secret, key = "kek" } } }
    }

    # Single api-server replica → a RWO hcloud volume is enough
    fileStorage = {
      provider = "local"
      local    = { size = var.storage_size, storageClassName = var.storage_class }
    }

    apiServer = {
      topology       = "monolith"
      serviceMonitor = { enabled = var.monitoring_enabled, namespace = var.namespace }
      web            = { resources = var.resources.api_server }
      extraEnv = [
        { name = "DT_OIDC_ENABLED", value = "true" },
        { name = "DT_OIDC_ISSUER", value = local.oidc_issuer },
        { name = "DT_OIDC_CLIENT_ID", value = var.oidc_client_id },
        { name = "DT_OIDC_USERNAME_CLAIM", value = "preferred_username" },
        { name = "DT_OIDC_USER_PROVISIONING", value = "true" },
        { name = "DT_OIDC_TEAM_SYNCHRONIZATION", value = "true" },
        { name = "DT_OIDC_TEAMS_CLAIM", value = "groups" },
      ]
    }

    frontend = {
      resources = var.resources.frontend
      extraEnv = [
        { name = "OIDC_ISSUER", value = local.oidc_issuer },
        { name = "OIDC_CLIENT_ID", value = var.oidc_client_id },
        { name = "OIDC_SCOPE", value = "openid profile email" },
        { name = "OIDC_FLOW", value = "code" },
        { name = "OIDC_LOGIN_BUTTON_TEXT", value = "dreitier (Microsoft)" },
      ]
    }

    # Internal: UI + full API (VPN). TLS ends at the internal Traefik (wildcard default certificate).
    ingress = {
      enabled          = true
      ingressClassName = var.internal_ingress_class
      hostname         = var.internal_hostname
    }
  })]

  # First start runs the schema migrations (startup probe budget 30 min)
  timeout = 1200

  depends_on = [kubernetes_manifest.db, kubernetes_manifest.kek]
}

# Public: BOM upload only (POST/PUT /api/v1/bom, GET /api/v1/bom/token/<uuid> for processing status)
# and /api/version (connectivity check of the upload actions). Auth: API key of a DT team.
resource "kubernetes_ingress_v1" "public" {
  metadata {
    name        = "${local.release_name}-public"
    namespace   = kubernetes_namespace_v1.this.metadata[0].name
    annotations = { "cert-manager.io/cluster-issuer" = var.cluster_issuer }
  }

  spec {
    ingress_class_name = var.public_ingress_class

    tls {
      hosts       = [var.public_hostname]
      secret_name = local.public_tls
    }

    rule {
      host = var.public_hostname
      http {
        path {
          path      = "/api/v1/bom"
          path_type = "Prefix"
          backend {
            service {
              name = local.api_service
              port { name = local.api_port_name }
            }
          }
        }
        path {
          path      = "/api/version"
          path_type = "Exact"
          backend {
            service {
              name = local.api_service
              port { name = local.api_port_name }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.this]
}
