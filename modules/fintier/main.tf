# fintier (dreitier/fintier): finance dashboard from DATEV BWA/SuSa PDFs. FastAPI + PostgreSQL, VPN only
# (internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak (client fintier, restricted
# to the access group – the application checks the "groups" claim as well).
# Secrets are never environment variables: one ExternalSecret renders one file per secret, mounted read-only
# at /run/secrets (the application's SECRETS_DIR):
#   data_key, session_key   <keys_kv_name>  (scripts/fintier-keys.sh, write once – data_key encrypts every
#                                            stored BWA/SuSa: losing it makes all data unreadable)
#   db_password             <db_kv_name>    (config/openbao-base, data/postgresql)
#   oidc_client_secret      <oidc_kv_name>  (config/keycloak, client fintier)
# The image is a private GHCR package → pull secret from <pull_kv_name> (shared with verschreibomat).
# The application reads the secrets at startup only: after a rotation restart the Deployment.
# The PDF import worker runs inside the application process. One replica; RollingUpdate is safe: the worker
# claims a job with SELECT … FOR UPDATE SKIP LOCKED inside its transaction (two pods never take the same
# job, a pod killed mid-import rolls back and the job stays queued), sessions are signed cookies with the
# shared session_key, and the schema exists already when the second pod starts (CREATE TABLE IF NOT EXISTS).

locals {
  name        = "fintier"
  secret      = "fintier-secrets"
  pull_secret = "ghcr-pull"
  uid         = 10001 # user of the image (USER 10001)
  oidc_issuer = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}"
  labels      = { "app.kubernetes.io/name" = local.name }
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
      target          = { name = local.secret, creationPolicy = "Owner" }
      # secretKey = file name below /run/secrets
      data = [
        { secretKey = "db_password", remoteRef = { key = var.db_kv_name, property = "user_${var.db_user}_pass" } },
        { secretKey = "data_key", remoteRef = { key = var.keys_kv_name, property = "data_key" } },
        { secretKey = "session_key", remoteRef = { key = var.keys_kv_name, property = "session_key" } },
        { secretKey = "oidc_client_secret", remoteRef = { key = var.oidc_kv_name, property = "client_secret" } },
      ]
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
    # no downtime on updates: the new pod must be ready (/healthz) before the old one stops
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
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
          fs_group        = local.uid # makes the secret files readable (mode 0440)
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = local.name
          image = var.image

          port {
            name           = "http"
            container_port = 8000
          }

          env {
            name  = "DB_HOST"
            value = var.db_host
          }
          env {
            name  = "PUBLIC_URL"
            value = "https://${var.hostname}"
          }
          # TLS ends at Traefik: session cookie only over https
          env {
            name  = "HTTPS_ONLY"
            value = "1"
          }
          # uvicorn: trust X-Forwarded-* from Traefik (only the ingress reaches the pod)
          env {
            name  = "FORWARDED_ALLOW_IPS"
            value = "*"
          }
          env {
            name  = "OIDC_ISSUER"
            value = local.oidc_issuer
          }
          env {
            name  = "OIDC_CLIENT_ID"
            value = var.oidc_client_id
          }
          env {
            name  = "OIDC_GROUP"
            value = var.access_group
          }
          env {
            name  = "OIDC_LABEL"
            value = var.oidc_label
          }
          # break-glass login with local users (python -m app.cli create-user, docs/fintier.md)
          env {
            name  = "LOCAL_LOGIN"
            value = var.local_login ? "1" : "0"
          }

          volume_mount {
            name       = "secrets"
            mount_path = "/run/secrets"
            read_only  = true
          }
          # uploads are spooled to /tmp
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

          # /healthz needs no login and checks the database
          startup_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            period_seconds    = 5
            failure_threshold = 24 # 2 minutes
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            period_seconds    = 30
            failure_threshold = 4 # a short database outage must not restart the pod
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = "http"
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
            size_limit = "256Mi" # up to 100 PDFs of 10 MB per upload (app limits)
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
