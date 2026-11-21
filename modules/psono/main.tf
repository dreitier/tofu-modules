# Psono password manager (dreitier/helm-charts psono): server + web client + admin portal in the combo
# image, VPN only (internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak (OIDC).
# Fresh installation – users export/import their data stores from the old instance (docs/migration.md).
# All secrets come from OpenBao through one ExternalSecret psono-server-env (chart: server.existingSecret):
#   k8s/prod/psono            server keys (scripts/psono-server-keys.sh, written once, never rotated)
#   <db_kv_name>              password of the database role (config/openbao-base, data/postgresql)
#   <oidc_kv_name>            Keycloak client secret (config/keycloak, client psono)
# Backups: the database via CNPG (data/postgresql); the chart's gobackup job needs static S3 keys → off.
# Fileserver (attachments, var.fileserver): own host on the internal Traefik (the browser talks to it
# directly), one amazon_s3 shard via IRSA (no keys), its keys from OpenBao via psono-fileserver-env.

locals {
  oidc_base = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}/protocol/openid-connect"
  # Not "psono-server": that's the chart's own Secret (settings.yaml) – same name = ESO can't own it
  secret = "psono-server-env"
  # Not "psono-fileserver": that's the chart's Secret (settings.yaml)
  fs_secret  = "psono-fileserver-env"
  fs_enabled = var.fileserver != null
  fs_keys    = ["PSONOFS_SECRET_KEY", "PSONOFS_PRIVATE_KEY", "PSONOFS_PUBLIC_KEY", "PSONOFS_CLUSTER_ID", "PSONOFS_CLUSTER_PRIVATE_KEY"]
  fs_token   = "/var/run/secrets/aws"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "server_secret" {
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
        template = {
          data = merge(
            { for k in local.server_keys : k => "{{ .${k} }}" },
            {
              PSONO_DATABASES_DEFAULT_USER     = var.db_user
              PSONO_DATABASES_DEFAULT_PASSWORD = "{{ .db_password }}"
              # Same keys as OIDC_CONFIGURATIONS in settings.yaml (provider 1 = the client's oidc_provider)
              PSONO_OIDC_CONFIGURATIONS = jsonencode({
                "1" = {
                  OIDC_RP_SIGN_ALGO              = "RS256"
                  OIDC_RP_CLIENT_ID              = var.oidc_client_id
                  OIDC_RP_CLIENT_SECRET          = "{{ .oidc_client_secret }}"
                  OIDC_OP_JWKS_ENDPOINT          = "${local.oidc_base}/certs"
                  OIDC_OP_AUTHORIZATION_ENDPOINT = "${local.oidc_base}/auth"
                  OIDC_OP_TOKEN_ENDPOINT         = "${local.oidc_base}/token"
                  OIDC_OP_USER_ENDPOINT          = "${local.oidc_base}/userinfo"
                  # Keycloak redirects back after logout only with client_id + post_logout_redirect_uri (in
                  # the client's valid_post_logout_redirect_uris); without them it stops at "You are logged out"
                  OIDC_OP_END_SESSION_ENDPOINT               = "${local.oidc_base}/logout?client_id=${urlencode(var.oidc_client_id)}&post_logout_redirect_uri=${urlencode("https://${var.hostname}/")}"
                  AUTOPROVISION_PSONO_GROUP                  = false
                  FORCE_MEMBERSHIP_OF_AUTOPROVISIONED_GROUPS = false
                  AUTOPROVISION_PSONO_FOLDER                 = false
                }
              })
            },
          )
        }
      }
      dataFrom = [{ extract = { key = var.keys_kv_name } }]
      data = [
        { secretKey = "db_password", remoteRef = { key = var.db_kv_name, property = var.db_kv_property } },
        { secretKey = "oidc_client_secret", remoteRef = { key = var.oidc_kv_name, property = "client_secret" } },
      ]
    }
  }
}

resource "kubernetes_manifest" "fileserver_secret" {
  count = local.fs_enabled ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = local.fs_secret, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target = {
        name           = local.fs_secret
        creationPolicy = "Owner"
        template       = { data = { for k in local.fs_keys : k => "{{ .${k} }}" } }
      }
      dataFrom = [{ extract = { key = var.fileserver.keys_kv_name } }]
    }
  }
}

locals {
  server_keys = [
    "PSONO_SECRET_KEY", "PSONO_ACTIVATION_LINK_SECRET", "PSONO_DB_SECRET", "PSONO_EMAIL_SECRET_SALT",
    "PSONO_PRIVATE_KEY", "PSONO_PUBLIC_KEY",
    # Admin account recovery: the server only needs the public key; the private key stays in OpenBao
    # (and the offline copy) for the admins
    "PSONO_ADMIN_RECOVERY_PUBLIC_KEY",
  ]
}

resource "helm_release" "this" {
  name       = "psono"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://dreitier.github.io/helm-charts/"
  chart      = "psono"
  version    = var.chart_version

  values = concat(
    [yamlencode({
      server = {
        host = var.hostname
        path = "/server"
        # TLS ends at the internal Traefik (wildcard default certificate) – the Ingress itself has no tls
        # section, the URLs Psono generates are https nonetheless
        forceTls = true
        ingress  = { enabled = true, ingressClassName = var.ingress_class, tls = false }

        allowedHosts      = ["*"]
        allowedDomains    = [var.user_domain]
        allowRegistration = false
        allowLostPassword = false

        existingSecret = local.secret
        oidc           = { enabled = true }

        db = {
          bundled = false
          name    = var.db_name
          host    = var.db_host
          port    = 5432
        }

        mail = { from = "psono@${var.user_domain}", host = var.smtp_host, port = 25 } # platform/mail-relay, no auth/TLS

        # Client IP for login notifications/audit: Django sits behind the combo image's nginx and Traefik,
        # so REMOTE_ADDR is 127.0.0.1 – take the address Traefik put into X-Forwarded-For (2nd from the
        # right). Traefik drops X-Forwarded-For from untrusted sources, so the header can't be spoofed.
        # Note: what Traefik sees is the LB / NetBird routing peer (no PROXY protocol, masquerade).
        extraEnv = [{ name = "PSONO_NUM_PROXIES", value = "2" }]

        resources = var.resources
        cronjob = {
          backup  = { enabled = false }
          cleanup = { resources = var.cleanup_resources } # cleartoken job
        }
      }

      client = {
        logonDomain = var.user_domain
        enableFiles = local.fs_enabled
        oidc        = { title = var.oidc_title, button = var.oidc_button }
      }

      fileserver = { enabled = false } # enabled by the second values document (var.fileserver)

      compliance = { securityReport = { enabled = false, interval = 0 } }
    })],
    # Fileserver as its own values document – a conditional between two different object shapes is a
    # type error ("Inconsistent conditional result types"), a list of strings is not
    [for fs in(local.fs_enabled ? [var.fileserver] : []) : yamlencode({
      fileserver = {
        enabled = true
        host    = fs.hostname
        path    = "/"
        # TLS ends at the internal Traefik (wildcard default certificate), see server
        forceTls     = true
        ingress      = { enabled = true, ingressClassName = var.ingress_class, tls = false }
        allowedHosts = ["*"]

        existingSecret  = local.fs_secret
        serverPublicKey = fs.server_public_key
        shards = [{
          shard_id          = fs.shard_id
          read              = true
          write             = true
          delete            = true
          allow_link_shares = true
          # No access_key/secret_key → boto3's default chain → web identity token (IRSA)
          engine = { class = "amazon_s3", kwargs = { bucket_name = fs.bucket } }
        }]

        extraEnv = [
          { name = "AWS_ROLE_ARN", value = fs.role_arn },
          { name = "AWS_WEB_IDENTITY_TOKEN_FILE", value = "${local.fs_token}/token" },
          { name = "AWS_REGION", value = fs.aws_region },
          { name = "AWS_DEFAULT_REGION", value = fs.aws_region },
          { name = "AWS_STS_REGIONAL_ENDPOINTS", value = "regional" },
        ]
        extraVolumes = [{
          name = "aws-token"
          projected = {
            sources = [{ serviceAccountToken = { audience = "sts.amazonaws.com", expirationSeconds = 86400, path = "token" } }]
          }
        }]
        extraVolumeMounts = [{ name = "aws-token", mountPath = local.fs_token, readOnly = true }]

        resources = fs.resources
      }
    })],
  )

  depends_on = [kubernetes_manifest.server_secret, kubernetes_manifest.fileserver_secret]
}
