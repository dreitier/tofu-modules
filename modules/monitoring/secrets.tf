# Secrets from OpenBao (ClusterSecretStore) – nothing secret in Helm values or the state

resource "kubernetes_manifest" "grafana_admin" {
  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = local.grafana_admin_secret, namespace = kubernetes_namespace_v1.this["monitoring"].metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.grafana_admin_secret
        creationPolicy = "Owner"
        template       = { data = { "admin-user" = "admin", "admin-password" = "{{ .password }}" } }
      }
      data = [{ secretKey = "password", remoteRef = { key = var.grafana_admin_kv_name, property = "user_admin_pass" } }]
    }
  }
}

resource "kubernetes_manifest" "grafana_oidc" {
  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = local.grafana_oidc_secret, namespace = kubernetes_namespace_v1.this["monitoring"].metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.grafana_oidc_secret, creationPolicy = "Owner" }
      data            = [{ secretKey = "client_secret", remoteRef = { key = var.grafana_oidc_kv_name, property = "client_secret" } }]
    }
  }
}

# Hetzner Object Storage credentials (Console → Security → S3 credentials, written by hand to OpenBao)
resource "kubernetes_manifest" "loki_s3" {
  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = local.loki_s3_secret, namespace = kubernetes_namespace_v1.this["loki"].metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.loki_s3_secret, creationPolicy = "Owner" }
      data = [
        { secretKey = "access_key", remoteRef = { key = var.loki_s3.kv_name, property = "access_key" } },
        { secretKey = "secret_key", remoteRef = { key = var.loki_s3.kv_name, property = "secret_key" } },
      ]
    }
  }
}

# Ping URL of the external heartbeat (healthchecks.io check, written by hand to OpenBao – docs/monitoring.md)
resource "kubernetes_manifest" "heartbeat" {
  count = var.heartbeat == null ? 0 : 1

  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = local.heartbeat_secret, namespace = kubernetes_namespace_v1.this["monitoring"].metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.heartbeat_secret, creationPolicy = "Owner" }
      data            = [{ secretKey = "ping_url", remoteRef = { key = var.heartbeat.kv_name, property = var.heartbeat.kv_property } }]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}
