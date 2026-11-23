# OpenBao (MPL fork of Vault) in HA mode with integrated storage (Raft). OpenBao dropped most external
# storage backends (tg-env's Vault used S3) → Raft on hcloud volumes, snapshots by CronJob (later).
# - Auto-unseal with AWS KMS via IRSA: projected service account token + AWS_* env, no static keys
#   (same pattern as tg-env, no pod identity webhook)
# - Self-initialization: on first start OpenBao initializes itself and runs the initialize requests below
#   (syntax checked against the OpenBao 2.7 docs, configuration/self-init). Runs once – changes need a
#   fresh storage. No root token, no recovery keys are handed out. The only bootstrap/break-glass login is
#   kubernetes auth (mount kubernetes-admin) with a short-lived token of the service account
#   openbao-admin: BASEMENT_BAO_AUTH=kubernetes BASEMENT_BAO_JWT=$(kubectl -n openbao create token openbao-admin).
#   (Cert auth was dropped: Traefik terminates TLS, the client certificate never reaches OpenBao.)
#   Everything else: config/openbao-base, config/openbao-oidc.

locals {
  token_dir  = "/var/run/secrets/eks.amazonaws.com/serviceaccount"
  plugin_dir = "/openbao/plugins"

  anti_affinity_term = {
    topologyKey = "kubernetes.io/hostname"
    labelSelector = { matchLabels = {
      "app.kubernetes.io/name"     = "openbao"
      "app.kubernetes.io/instance" = "openbao"
      component                    = "server"
    } }
  }

  config = <<-EOT
    ui = true

    listener "tcp" {
      address         = "[::]:8200"
      cluster_address = "[::]:8201"
      tls_disable     = true
      %{if var.monitoring_enabled}
      # /v1/sys/metrics without a token, for Prometheus (ServiceMonitor below). Only counters/gauges, no secrets;
      # reachable by everyone who reaches the API (cluster, VPN).
      telemetry {
        unauthenticated_metrics_access = true
      }
      %{endif}
    }
    %{if var.monitoring_enabled}

    telemetry {
      prometheus_retention_time = "24h"
      disable_hostname          = true
    }
    %{endif}

    storage "raft" {
      path = "/openbao/data"
      retry_join {
        auto_join        = "provider=k8s label_selector=\"app.kubernetes.io/name=openbao,component=server\" namespace=\"${var.namespace}\""
        auto_join_scheme = "http"
      }
    }

    # Since OpenBao 2.7 the KMS seals are external plugins: downloaded from the OCI image on every start
    # (pinned by digest) into an emptyDir, registered from this config. The plugin inherits the server's
    # environment (AWS_* for IRSA).
    plugin_directory     = "${local.plugin_dir}"
    plugin_auto_download = true

    plugin "kms" "awskms" {
      image = "${var.kms_plugin_image}"
    }

    seal "awskms" {
      region     = "${var.aws_region}"
      kms_key_id = "${var.kms_key_id}"
    }

    service_registration "kubernetes" {}

  EOT

  # Self-init only on the first pod (openbao-0): with initialize in the shared config every pod that
  # starts before joining initializes its own cluster (openbao/openbao#2274, seen 2026-11-10: three
  # independent clusters behind one ingress). Each pod loads /openbao/self-init/<pod name>.hcl in
  # addition; only openbao-0.hcl has the initialize blocks, the others join via retry_join.
  self_init_dir    = "/openbao/self-init"
  self_init_config = <<-EOT
    # Break-glass/bootstrap admin login: kubernetes auth on its own mount (kubernetes-admin), role admin,
    # bound to the service account ${var.namespace}/${var.admin_service_account}. Whoever may create tokens
    # for it (cluster admins via Rancher) is OpenBao admin. config/openbao-base manages the separate mount
    # "kubernetes" for workloads (ESO) – this one is never touched by Tofu.
    initialize "auth" {
      request "enable-kubernetes-admin" {
        operation = "update"
        path      = "sys/auth/kubernetes-admin"
        data      = { type = "kubernetes" }
      }
      request "kubernetes-admin-config" {
        operation = "update"
        path      = "auth/kubernetes-admin/config"
        # OpenBao reviews tokens with its own service account (chart: authDelegator)
        data = { kubernetes_host = "https://kubernetes.default.svc" }
      }
    }

    initialize "policy" {
      request "admin-policy" {
        operation = "update"
        path      = "sys/policies/acl/admin"
        data = {
          policy = <<-EOP
            path "*" {
              capabilities = ["create", "read", "update", "delete", "list", "sudo"]
            }
          EOP
        }
      }
    }

    initialize "admin" {
      request "admin-role" {
        operation = "update"
        path      = "auth/kubernetes-admin/role/admin"
        data = {
          bound_service_account_names      = ["${var.admin_service_account}"]
          bound_service_account_namespaces = ["${var.namespace}"]
          token_policies                   = ["admin"]
          token_ttl                        = "1h"
        }
      }
    }
  EOT
}

# Per-pod extra config (see local.self_init_config)
resource "kubernetes_config_map_v1" "self_init" {
  metadata {
    name      = "openbao-self-init"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  data = {
    for i in range(var.replicas) : "openbao-${i}.hcl" => (
      i == 0 ? local.self_init_config : "# joins the cluster of openbao-0 via retry_join, no self-init\n"
    )
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

# Service account of the break-glass admin role (self-init above) – only used for `kubectl create token`
resource "kubernetes_service_account_v1" "admin" {
  metadata {
    name      = var.admin_service_account
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  automount_service_account_token = false
}

resource "helm_release" "this" {
  name       = "openbao"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://openbao.github.io/openbao-helm"
  chart      = "openbao"
  version    = var.chart_version

  values = [yamlencode({
    server = {
      ha = {
        enabled  = true
        replicas = var.replicas
        raft = {
          enabled   = true
          setNodeId = true
          config    = local.config
        }
      }
      # One pod per node. The chart's default is a hard rule; with fewer nodes than replicas it is relaxed to
      # a preference (otherwise a pod stays Pending) – then losing the node with two pods loses the quorum.
      affinity = {
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [
            for t in [local.anti_affinity_term] : t if var.anti_affinity_required
          ]
          preferredDuringSchedulingIgnoredDuringExecution = [
            for t in [local.anti_affinity_term] : { weight = 100, podAffinityTerm = t } if !var.anti_affinity_required
          ]
        }
      }
      # Auto-unseal makes restarts safe → rolling updates (tg-env lesson: OnDelete hid unrolled changes)
      updateStrategyType = "RollingUpdate"
      # Checksum of the server config as pod annotation: a config change rolls the pods (without it the new
      # ConfigMap only takes effect after a manual restart – seen 2026-11-17 with the telemetry change)
      configAnnotation = true
      dataStorage      = { enabled = true, size = var.storage_size, storageClass = var.storage_class }
      resources        = var.resources
      # JSON logs (BAO_LOG_FORMAT), parsed by Alloy (basement config/alloy/workload-logs.alloy)
      logFormat = "json"

      extraEnvironmentVars = {
        AWS_ROLE_ARN                = var.irsa_role_arn
        AWS_WEB_IDENTITY_TOKEN_FILE = "${local.token_dir}/token"
        AWS_REGION                  = var.aws_region
        AWS_STS_REGIONAL_ENDPOINTS  = "regional"
      }
      # Second config file per pod (shell-expanded in the chart's server command)
      extraArgs = "-config=${local.self_init_dir}/$HOSTNAME.hcl"

      volumes = [{
        name     = "plugins"
        emptyDir = {}
        }, {
        name      = "self-init"
        configMap = { name = kubernetes_config_map_v1.self_init.metadata[0].name }
        }, {
        name = "aws-token"
        projected = {
          sources = [{
            serviceAccountToken = { audience = "sts.amazonaws.com", expirationSeconds = 86400, path = "token" }
          }]
        }
      }]
      volumeMounts = [
        { name = "aws-token", mountPath = local.token_dir, readOnly = true },
        { name = "plugins", mountPath = local.plugin_dir },
        { name = "self-init", mountPath = local.self_init_dir, readOnly = true },
      ]

      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class
        hosts            = [{ host = var.hostname, paths = [] }]
        # TLS: wildcard default certificate of the internal Traefik (platform/internal-tls)
      }
    }
    injector = { enabled = false }

    # ServiceMonitor for /v1/sys/metrics?format=prometheus – in HA mode the chart scrapes the active node only
    # (service openbao-active); standby health comes from its autopilot metrics
    serverTelemetry = {
      serviceMonitor = { enabled = var.monitoring_enabled, interval = "30s", scrapeTimeout = "10s" }
    }
  })]

  lifecycle {
    prevent_destroy = true
  }
}

# --- Raft snapshots ---------------------------------------------------------------------------------
# CronJob: an init container logs in with kubernetes auth (role openbao-snapshot, policy raft-snapshot –
# config/openbao-base) and saves a snapshot from the active node; the second container uploads it to S3
# via IRSA (role with PutObject only, retention = the bucket's lifecycle rule). The snapshot holds the
# barrier-encrypted data – useless without the KMS unseal key.
# Restore: bao operator raft snapshot restore -force <file> (docs/openbao.md).

resource "kubernetes_service_account_v1" "snapshot" {
  count = var.snapshot == null ? 0 : 1

  metadata {
    name      = "openbao-snapshot"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
}

resource "kubernetes_cron_job_v1" "snapshot" {
  count = var.snapshot == null ? 0 : 1

  metadata {
    name      = "openbao-snapshot"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    schedule                      = var.snapshot.schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {}
      spec {
        backoff_limit = 2

        template {
          metadata {}
          spec {
            service_account_name = kubernetes_service_account_v1.snapshot[0].metadata[0].name
            restart_policy       = "Never"

            init_container {
              name    = "snapshot"
              image   = var.snapshot.openbao_image
              command = ["sh", "-ec"]
              args = [<<-EOT
                export BAO_TOKEN="$(bao write -field=token auth/${var.snapshot.auth_mount}/login role=${var.snapshot.auth_role} jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token)"
                bao operator raft snapshot save /snapshot/openbao.snap
                ls -l /snapshot/openbao.snap
              EOT
              ]
              env {
                name  = "BAO_ADDR"
                value = "http://openbao-active.${var.namespace}.svc:8200"
              }
              volume_mount {
                name       = "snapshot"
                mount_path = "/snapshot"
              }
              resources {
                requests = var.snapshot_resources.snapshot.requests
                limits   = var.snapshot_resources.snapshot.limits
              }
            }

            container {
              name    = "upload"
              image   = var.snapshot.aws_cli_image
              command = ["sh", "-ec"]
              args = [<<-EOT
                key="${var.snapshot.prefix}/openbao-$(date -u +%Y%m%dT%H%M%SZ).snap"
                aws s3 cp --no-progress /snapshot/openbao.snap "s3://${var.snapshot.bucket}/$key"
                echo "uploaded s3://${var.snapshot.bucket}/$key"
              EOT
              ]
              resources {
                requests = var.snapshot_resources.upload.requests
                limits   = var.snapshot_resources.upload.limits
              }
              env {
                name  = "AWS_ROLE_ARN"
                value = var.snapshot.role_arn
              }
              env {
                name  = "AWS_WEB_IDENTITY_TOKEN_FILE"
                value = "/var/run/secrets/aws/token"
              }
              env {
                name  = "AWS_REGION"
                value = var.aws_region
              }
              env {
                name  = "AWS_STS_REGIONAL_ENDPOINTS"
                value = "regional"
              }
              volume_mount {
                name       = "snapshot"
                mount_path = "/snapshot"
                read_only  = true
              }
              volume_mount {
                name       = "aws-token"
                mount_path = "/var/run/secrets/aws"
                read_only  = true
              }
            }

            volume {
              name = "snapshot"
              empty_dir {}
            }
            volume {
              name = "aws-token"
              projected {
                sources {
                  service_account_token {
                    audience           = "sts.amazonaws.com"
                    expiration_seconds = 3600
                    path               = "token"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
