# Shared PostgreSQL (CloudNativePG cluster), taken from tg-env. Bootstrap: initdb, or a one-time
# monolith import (import_source) when migrating databases. Roles get their passwords from OpenBao
# (managed roles via ExternalSecrets), backups go to S3 via the Barman Cloud plugin with IRSA
# (projected token, no webhook).

locals {
  external_secret_api = "external-secrets.io/v1"
  plugin_name         = "barman-cloud.cloudnative-pg.io"
  token_file          = "/projected/aws-token"
  backup_server_name  = coalesce(var.backup_server_name, var.cluster_name)
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

# --- Secrets from Vault ---------------------------------------------------------------------------

# Role passwords (basic-auth secrets for managed roles)
resource "kubernetes_manifest" "role_secret" {
  for_each = var.roles

  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = "${var.cluster_name}-role-${each.key}", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "15m"
      secretStoreRef  = { name = var.secret_store_name, kind = "ClusterSecretStore" }
      target = {
        name           = "${var.cluster_name}-role-${each.key}"
        creationPolicy = "Owner"
        deletionPolicy = "Delete"
        template = {
          type = "kubernetes.io/basic-auth"
          metadata = {
            # CNPG reconciles the role when the secret changes
            labels = { "cnpg.io/reload" = "true" }
          }
          data = { username = each.key, password = "{{ .password }}" }
        }
      }
      data = [
        { secretKey = "password", remoteRef = { key = lookup(var.role_vault_keys, each.key, var.vault_key), property = "user_${each.key}_pass" } },
      ]
    }
  }
}

# Superuser password of the Bitnami instance – only used by the import at bootstrap
resource "kubernetes_manifest" "import_source_secret" {
  count = var.import_source == null ? 0 : 1

  manifest = {
    apiVersion = local.external_secret_api
    kind       = "ExternalSecret"
    metadata   = { name = "${var.cluster_name}-import-source", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      refreshInterval = "15m"
      secretStoreRef  = { name = var.secret_store_name, kind = "ClusterSecretStore" }
      target          = { name = "${var.cluster_name}-import-source", creationPolicy = "Owner", deletionPolicy = "Delete" }
      data = [
        { secretKey = "password", remoteRef = { key = var.vault_key, property = var.import_source.password_property } },
      ]
    }
  }
}

# --- Backups ----------------------------------------------------------------------------------------

resource "kubernetes_manifest" "object_store" {
  manifest = {
    apiVersion = "barmancloud.cnpg.io/v1"
    kind       = "ObjectStore"
    metadata   = { name = "${var.cluster_name}-backup", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      retentionPolicy = var.backup_retention
      configuration = {
        destinationPath = var.backup_destination
        s3Credentials   = { inheritFromIAMRole = true }
        wal             = { compression = "gzip" }
        data            = { compression = "gzip" }
      }
      # IRSA without a webhook: the sidecar shares the instance pod's volumes (/projected)
      instanceSidecarConfiguration = {
        # plugin-barman-cloud sidecar (+ init) in the instance pods; a change restarts the instances (rolling)
        resources = var.backup_sidecar_resources
        env = [
          { name = "AWS_ROLE_ARN", value = var.backup_role_arn },
          { name = "AWS_WEB_IDENTITY_TOKEN_FILE", value = local.token_file },
          { name = "AWS_REGION", value = var.aws_region },
          { name = "AWS_DEFAULT_REGION", value = var.aws_region },
          { name = "AWS_STS_REGIONAL_ENDPOINTS", value = "regional" },
        ]
      }
    }
  }
}

# --- Cluster ----------------------------------------------------------------------------------------

resource "kubernetes_manifest" "cluster" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata   = { name = var.cluster_name, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = merge(
      {
        instances             = var.instances
        imageName             = var.image
        primaryUpdateMethod   = var.primary_update_method
        enableSuperuserAccess = false
        storage               = { storageClass = var.storage_class, size = var.storage_size }
        resources             = var.resources

        managed = {
          roles = [for r in sort(var.roles) : {
            name           = r
            ensure         = "present"
            login          = true
            passwordSecret = { name = "${var.cluster_name}-role-${r}" }
          }]
        }

        plugins = [{
          name          = local.plugin_name
          isWALArchiver = true
          parameters = {
            barmanObjectName = kubernetes_manifest.object_store.manifest.metadata.name
            serverName       = local.backup_server_name
          }
        }]

        # Token for IRSA (audience sts.amazonaws.com), mounted at /projected
        projectedVolumeTemplate = {
          sources = [{
            serviceAccountToken = { audience = "sts.amazonaws.com", expirationSeconds = 86400, path = "aws-token" }
          }]
        }

        # enablePodMonitor is deprecated (CNPG 1.26+) and created nothing here (operator started before the
        # Prometheus Operator CRDs existed) → own PodMonitor below
        monitoring = { enablePodMonitor = false }
      },
      # Bootstrap by import (only when import_source is set; a list expansion avoids an
      # inconsistent conditional type)
      [for src in(var.import_source == null ? [] : [var.import_source]) : {
        bootstrap = {
          initdb = {
            import = {
              type      = "monolith"
              databases = keys(var.databases)
              roles     = sort(var.roles)
              source    = { externalCluster = "import-source" }
            }
          }
        }
        externalClusters = [{
          name = "import-source"
          connectionParameters = {
            host    = src.host
            user    = "postgres"
            dbname  = "postgres"
            sslmode = "disable"
          }
          password = { name = "${var.cluster_name}-import-source", key = "password" }
        }]
      }]...
    )
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
  # update: a major upgrade (new imageName) stops all instances, runs pg_upgrade and re-clones the replicas
  timeouts {
    create = "20m"
    update = "30m"
  }

  depends_on = [kubernetes_manifest.role_secret, kubernetes_manifest.import_source_secret]
}

# Databases (adopted after the import; never dropped by Tofu)
resource "kubernetes_manifest" "database" {
  for_each = var.manage_databases ? var.databases : {}

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Database"
    metadata   = { name = "${var.cluster_name}-${replace(each.key, "_", "-")}", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    # extensions only when there are any: the API server drops an empty list (omitempty), so "extensions = []"
    # came back as null and showed up as an in-place update on the next plan after every new database.
    # A for expression instead of a conditional – both branches of a conditional need the same object type.
    spec = merge(
      {
        name                  = each.key
        owner                 = each.value.owner
        cluster               = { name = var.cluster_name }
        ensure                = "present"
        databaseReclaimPolicy = "retain"
      },
      { for k, v in { extensions = [for e in each.value.extensions : { name = e, ensure = "present" }] } : k => v if length(v) > 0 },
    )
  }

  depends_on = [kubernetes_manifest.cluster]
}

# Metrics of every instance (port "metrics", 9187): PostgreSQL + Barman Cloud plugin (backup timestamps)
resource "kubernetes_manifest" "pod_monitor" {
  count = var.monitoring_enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata   = { name = var.cluster_name, namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      selector = { matchLabels = { "cnpg.io/cluster" = var.cluster_name } }
      podMetricsEndpoints = [{
        port = "metrics"
        # CNPG cluster name as cnpg_cluster – "cluster" is the Kubernetes cluster (dreitier, scrape class of
        # platform/monitoring); CNPG's own dashboard would need its cluster variable pointed at cnpg_cluster
        relabelings = [{ sourceLabels = ["__meta_kubernetes_pod_label_cnpg_io_cluster"], targetLabel = "cnpg_cluster" }]
      }]
    }
  }
}

resource "kubernetes_manifest" "scheduled_backup" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "ScheduledBackup"
    metadata   = { name = "${var.cluster_name}-daily", namespace = kubernetes_namespace_v1.this.metadata[0].name }
    spec = {
      schedule             = var.backup_schedule
      immediate            = true
      backupOwnerReference = "self"
      cluster              = { name = var.cluster_name }
      method               = "plugin"
      pluginConfiguration  = { name = local.plugin_name }
    }
  }

  depends_on = [kubernetes_manifest.cluster]
}

# Old service name postgresql.<ns>.svc → read-write service of the cluster (apps keep their DB host).
# Only after the Bitnami release (which owns a Service "postgresql") is gone.
resource "kubernetes_service_v1" "alias" {
  count = var.alias_service_name == null ? 0 : 1

  metadata {
    name      = var.alias_service_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "${var.cluster_name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}.svc.cluster.local"
    port {
      name = "postgresql"
      port = 5432
    }
  }
}
