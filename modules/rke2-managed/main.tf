# Cloud credential used for etcd snapshots to S3. The rancher2 provider has no write-only key
# attributes, so Tofu only writes placeholders (ignored afterwards) and the ExternalSecret below
# merges the real keys from Vault into the credential's Secret – no AWS keys in the state.
# An existing credential can be adopted with:
#   terragrunt import 'rancher2_cloud_credential.etcd_s3[0]' cattle-global-data:<cc-id>.<driver>
resource "rancher2_cloud_credential" "etcd_s3" {
  count = var.etcd_s3_credential == null ? 0 : 1

  lifecycle {
    ignore_changes = [
      s3_credential_config[0].access_key,
      s3_credential_config[0].secret_key,
      amazonec2_credential_config[0].access_key,
      amazonec2_credential_config[0].secret_key,
    ]
  }

  name        = var.etcd_s3_credential.name
  description = var.etcd_s3_credential.description

  dynamic "s3_credential_config" {
    for_each = var.etcd_s3_credential.driver == "s3" ? [1] : []
    content {
      access_key     = local.etcd_s3_placeholder
      secret_key     = local.etcd_s3_placeholder
      default_region = local.etcd_s3_region
    }
  }

  dynamic "amazonec2_credential_config" {
    for_each = var.etcd_s3_credential.driver == "amazonec2" ? [1] : []
    content {
      access_key     = local.etcd_s3_placeholder
      secret_key     = local.etcd_s3_placeholder
      default_region = local.etcd_s3_region
    }
  }
}

# Real keys for the cloud credential: ExternalSecret on Rancher's local cluster (ClusterSecretStore
# with read access to Vault) merges them into the credential's Secret cattle-global-data/<cc-id>.
# Key names follow Rancher's schema <driver>credentialConfig-<field>.
resource "kubernetes_manifest" "etcd_s3_external_secret" {
  provider = kubernetes.rancher_local
  count    = var.etcd_s3_credential == null ? 0 : 1

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "${split(":", rancher2_cloud_credential.etcd_s3[0].id)[1]}-keys"
      namespace = "cattle-global-data"
    }
    spec = {
      refreshInterval = var.etcd_s3_credential.refresh_interval
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = var.etcd_s3_credential.secret_store
      }
      target = {
        name           = split(":", rancher2_cloud_credential.etcd_s3[0].id)[1]
        creationPolicy = "Merge"
        deletionPolicy = "Retain"
      }
      data = [
        {
          secretKey = "${var.etcd_s3_credential.driver}credentialConfig-accessKey"
          remoteRef = { key = var.etcd_s3_credential.vault_path, property = var.etcd_s3_credential.access_key_id_field }
        },
        {
          secretKey = "${var.etcd_s3_credential.driver}credentialConfig-secretKey"
          remoteRef = { key = var.etcd_s3_credential.vault_path, property = var.etcd_s3_credential.secret_access_key_field }
        },
      ]
    }
  }
}

# To adopt an already existing cluster:
#   terragrunt import rancher2_cluster_v2.this fleet-default/<cluster>
resource "rancher2_cluster_v2" "this" {
  name               = var.cluster_name
  fleet_namespace    = var.fleet_namespace
  kubernetes_version = var.kubernetes_version

  enable_network_policy = var.enable_network_policy
  labels                = var.labels
  annotations           = var.annotations

  default_pod_security_admission_configuration_template_name = var.pod_security_admission_template

  # Rancher's agents: extra tolerations (var.agent_tolerations, e.g. the "uninitialized" taint of an out-of-tree
  # cloud controller: the cluster agent must run before the CCM, which is installed through it) plus an optional
  # affinity/resources override per agent (var.cluster_agent_customization / var.fleet_agent_customization)
  dynamic "cluster_agent_deployment_customization" {
    for_each = local.cluster_agent_customization
    content {
      override_affinity = cluster_agent_deployment_customization.value.override_affinity

      dynamic "append_tolerations" {
        for_each = var.agent_tolerations
        content {
          key      = append_tolerations.value.key
          operator = append_tolerations.value.operator
          value    = append_tolerations.value.value
          effect   = append_tolerations.value.effect
        }
      }

      dynamic "override_resource_requirements" {
        for_each = cluster_agent_deployment_customization.value.resources == null ? [] : [cluster_agent_deployment_customization.value.resources]
        content {
          cpu_request    = override_resource_requirements.value.cpu_request
          cpu_limit      = override_resource_requirements.value.cpu_limit
          memory_request = override_resource_requirements.value.memory_request
          memory_limit   = override_resource_requirements.value.memory_limit
        }
      }
    }
  }

  dynamic "fleet_agent_deployment_customization" {
    for_each = local.fleet_agent_customization
    content {
      override_affinity = fleet_agent_deployment_customization.value.override_affinity

      dynamic "append_tolerations" {
        for_each = var.agent_tolerations
        content {
          key      = append_tolerations.value.key
          operator = append_tolerations.value.operator
          value    = append_tolerations.value.value
          effect   = append_tolerations.value.effect
        }
      }

      dynamic "override_resource_requirements" {
        for_each = fleet_agent_deployment_customization.value.resources == null ? [] : [fleet_agent_deployment_customization.value.resources]
        content {
          cpu_request    = override_resource_requirements.value.cpu_request
          cpu_limit      = override_resource_requirements.value.cpu_limit
          memory_request = override_resource_requirements.value.memory_request
          memory_limit   = override_resource_requirements.value.memory_limit
        }
      }
    }
  }

  dynamic "local_auth_endpoint" {
    for_each = var.local_auth_endpoint == null ? [] : [var.local_auth_endpoint]
    content {
      enabled  = local_auth_endpoint.value.enabled
      fqdn     = local_auth_endpoint.value.fqdn
      ca_certs = local_auth_endpoint.value.ca_certs
    }
  }

  rke_config {
    machine_global_config = var.machine_global_config == null ? null : yamlencode(var.machine_global_config)
    chart_values          = var.chart_values == null ? null : yamlencode(var.chart_values)
    additional_manifest   = var.additional_manifest

    dynamic "machine_selector_config" {
      for_each = var.machine_selector_config
      content {
        config = machine_selector_config.value.config == null ? null : yamlencode(machine_selector_config.value.config)

        dynamic "machine_label_selector" {
          for_each = machine_selector_config.value.match_labels == null ? [] : [machine_selector_config.value.match_labels]
          content {
            match_labels = machine_label_selector.value
          }
        }
      }
    }

    upgrade_strategy {
      control_plane_concurrency = var.upgrade_strategy.control_plane_concurrency
      worker_concurrency        = var.upgrade_strategy.worker_concurrency

      control_plane_drain_options {
        enabled                              = var.upgrade_strategy.control_plane_drain.enabled
        force                                = var.upgrade_strategy.control_plane_drain.force
        ignore_daemon_sets                   = var.upgrade_strategy.control_plane_drain.ignore_daemon_sets
        delete_empty_dir_data                = var.upgrade_strategy.control_plane_drain.delete_empty_dir_data
        disable_eviction                     = var.upgrade_strategy.control_plane_drain.disable_eviction
        grace_period                         = var.upgrade_strategy.control_plane_drain.grace_period
        timeout                              = var.upgrade_strategy.control_plane_drain.timeout
        skip_wait_for_delete_timeout_seconds = var.upgrade_strategy.control_plane_drain.skip_wait_for_delete_timeout_seconds
      }
      worker_drain_options {
        enabled                              = var.upgrade_strategy.worker_drain.enabled
        force                                = var.upgrade_strategy.worker_drain.force
        ignore_daemon_sets                   = var.upgrade_strategy.worker_drain.ignore_daemon_sets
        delete_empty_dir_data                = var.upgrade_strategy.worker_drain.delete_empty_dir_data
        disable_eviction                     = var.upgrade_strategy.worker_drain.disable_eviction
        grace_period                         = var.upgrade_strategy.worker_drain.grace_period
        timeout                              = var.upgrade_strategy.worker_drain.timeout
        skip_wait_for_delete_timeout_seconds = var.upgrade_strategy.worker_drain.skip_wait_for_delete_timeout_seconds
      }
    }

    etcd {
      disable_snapshots      = var.etcd.disable_snapshots
      snapshot_schedule_cron = var.etcd.snapshot_schedule_cron
      snapshot_retention     = var.etcd.snapshot_retention

      dynamic "s3_config" {
        for_each = var.etcd.s3 == null ? [] : [var.etcd.s3]
        content {
          bucket                = s3_config.value.bucket
          endpoint              = s3_config.value.endpoint
          region                = s3_config.value.region
          folder                = s3_config.value.folder
          cloud_credential_name = local.etcd_s3_cloud_credential_name
          endpoint_ca           = s3_config.value.endpoint_ca
          skip_ssl_verify       = s3_config.value.skip_ssl_verify
        }
      }
    }

    dynamic "rotate_certificates" {
      for_each = var.rotate_certificates_generation == null ? [] : [var.rotate_certificates_generation]
      content {
        generation = rotate_certificates.value
      }
    }
  }

  lifecycle {
    # A downstream cluster must never be deleted by accident
    prevent_destroy = true

    # Set by Rancher when a snapshot is taken/restored in the UI ("Snapshot Now", restore);
    # the generation counter is an action trigger, not desired state
    ignore_changes = [
      rke_config[0].etcd_snapshot_create,
      rke_config[0].etcd_snapshot_restore,
    ]
  }
}

# Registration token for node_command. Rancher maintains only "default-token" itself, and that one
# authenticates the cattle-cluster-agent but cannot register custom machines in Rancher 2.15
# ("500 machine not found by request", 2026-10-26); the UI creates throwaway tokens with random names.
# Rancher fills status and the value (secret crt-token-<name>); the token expires after 30 days
# (status.expiresAt) → apply this unit before every new node.
# Rotate: delete secret crt-token-<name> and this object in Rancher, then apply.
resource "kubernetes_manifest" "registration_token" {
  provider = kubernetes.rancher_local

  manifest = {
    apiVersion = "management.cattle.io/v3"
    kind       = "ClusterRegistrationToken"
    metadata = {
      name      = var.registration_token_name
      namespace = rancher2_cluster_v2.this.cluster_v1_id
    }
    spec = {
      clusterName = rancher2_cluster_v2.this.cluster_v1_id
    }
  }
}

# Cluster-scoped token for the direct kubeconfig (authorized cluster endpoint, locals.tf). Rancher syncs
# cluster-scoped tokens to the downstream cluster (ClusterAuthToken), where kube-api-auth validates them.
# Rancher caps the TTL at auth-token-max-ttl-minutes; renew recreates an expired token on the next apply
# (then re-run the platform units).
resource "rancher2_token" "kube_config" {
  count       = try(var.local_auth_endpoint.server, null) == null ? 0 : 1
  cluster_id  = rancher2_cluster_v2.this.cluster_v1_id
  description = "OpenTofu platform units (${var.cluster_name}, direct API endpoint)"
  ttl         = var.kube_config_token_ttl_seconds
  renew       = true
}
