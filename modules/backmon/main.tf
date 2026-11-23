# backmon (dreitier/backmon): monitors the backup files in S3 buckets and exposes Prometheus metrics. Installed
# with our own chart (dreitier/helm-charts backmon), VPN only (internal Traefik, wildcard certificate
# *.intern.<domain>), no login – backmon has no OIDC; downloads are off, the UI shows names, sizes and dates only.
# S3 without keys: IRSA role <role_arn> (aws/irsa-prod, trusts the service account <namespace>/backmon) via a
# projected token – backmon falls back to the AWS default credential chain when the environment has no keys.
# The role may list the buckets and read their backup_definitions.yaml, nothing else → no bucket discovery
# (s3:ListAllMyBuckets), the buckets are listed in disks.include.
# Each bucket needs a backup_definitions.yaml in its root; without one backmon reports the disk with
# backmon_definition_status = 1.
# Alerts: the chart's PrometheusRule (var.alerts_enabled, off by default). Metrics: ServiceMonitor.
# The namespace holds no credentials: the chart's Secret is the configuration file (bucket names only).
# CI (docs/ci-deploy.md of basement): Helm keeps its release in Secrets of the namespace → the runner needs the
# Helm rights of modules/arc-runners (helm_app_namespaces).

locals {
  name = "backmon"
  uid  = 65532 # nonroot user of the distroless image (backmon >= 4.0.0)

  # "ghcr.io/dreitier/backmon:6.2.1" → repository + tag (the unit keeps one image string: update-app.yml of
  # basement replaces it)
  image_repository = regex("^(.+):([^:/]+)$", var.image)[0]
  image_tag        = regex("^(.+):([^:/]+)$", var.image)[1]

  aws_token_dir = "/var/run/secrets/aws"

  config = {
    port            = 8000
    log_level       = var.log_level
    update_interval = var.update_interval
    downloads       = { enabled = false }
    environments = {
      (var.environment_name) = {
        s3 = {
          region              = var.aws_region
          auto_discover_disks = false
        }
        disks = {
          include    = var.buckets
          all_others = "exclude"
        }
      }
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://dreitier.github.io/helm-charts/"
  chart      = "backmon"
  version    = var.chart_version

  values = [yamlencode({
    fullnameOverride = local.name

    image = {
      repository = local.image_repository
      tag        = local.image_tag
    }

    # the IRSA role trusts exactly this service account; its token is mounted as a projected volume below
    # (audience sts.amazonaws.com), the default API token is not needed
    serviceAccount = {
      create                       = true
      name                         = local.name
      automountServiceAccountToken = false
    }

    backmon = {
      config = {
        enabled = true
        content = yamlencode(local.config)
      }
    }

    extraEnv = [
      { name = "AWS_ROLE_ARN", value = var.role_arn },
      { name = "AWS_WEB_IDENTITY_TOKEN_FILE", value = "${local.aws_token_dir}/token" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      { name = "AWS_STS_REGIONAL_ENDPOINTS", value = "regional" },
    ]
    extraVolumes = [
      {
        name = "aws-token"
        projected = {
          sources = [{ serviceAccountToken = { audience = "sts.amazonaws.com", expirationSeconds = 86400, path = "token" } }]
        }
      },
      # backmon downloads each backup_definitions.yaml into os.TempDir()
      { name = "tmp", emptyDir = { sizeLimit = "16Mi" } },
    ]
    extraVolumeMounts = [
      { name = "aws-token", mountPath = local.aws_token_dir, readOnly = true },
      { name = "tmp", mountPath = "/tmp" },
    ]

    # Pod Security "restricted" (Kyverno); fsGroup makes the projected token readable
    podSecurityContext = {
      runAsNonRoot   = true
      runAsUser      = local.uid
      runAsGroup     = local.uid
      fsGroup        = local.uid
      seccompProfile = { type = "RuntimeDefault" }
    }
    securityContext = {
      runAsNonRoot             = true
      allowPrivilegeEscalation = false
      readOnlyRootFilesystem   = true
      capabilities             = { drop = ["ALL"] }
    }

    resources = var.resources

    # TLS ends at the internal Traefik (wildcard default certificate) – no tls section
    ingress = {
      enabled   = true
      className = var.ingress_class
      hosts = [{
        host  = var.hostname
        paths = [{ path = "/", pathType = "Prefix" }]
      }]
    }

    # both need the Prometheus Operator CRDs (monitoring.coreos.com)
    serviceMonitor = { enabled = var.monitoring_enabled }
    prometheusRules = merge(var.alert_rules, {
      enabled = var.alerts_enabled
    })
  })]

  lifecycle {
    precondition {
      condition     = !var.alerts_enabled || var.monitoring_enabled
      error_message = "alerts_enabled needs monitoring_enabled (the alerts evaluate the scraped metrics)."
    }
  }
}
