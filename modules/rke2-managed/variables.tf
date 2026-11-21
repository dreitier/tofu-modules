# --- Rancher access -----------------------------------------------------------

variable "sops_file" {
  type        = string
  description = "SOPS encrypted file containing required secrets"
}

variable "rancher_url" {
  type        = string
  description = "URL of the Rancher server"
}

variable "rancher_admin_user" {
  type        = string
  description = "Rancher (local provider) user used by OpenTofu"
}

variable "rancher_password_sops_key" {
  type        = string
  description = "Key inside the SOPS file holding the password of rancher_admin_user"
  default     = "admin_password"
}

variable "rancher_login_path" {
  type        = string
  description = "Path of the Rancher local login endpoint"
  default     = "/v3-public/localProviders/local?action=login"
}

variable "rancher_token_ttl_minutes" {
  type        = number
  description = "Lifetime of the token created by the login on every run"
  default     = 60
}

variable "rancher_ca_cert_pem" {
  type        = string
  description = "PEM encoded CA certificate(s) of the Rancher server; null uses the system trust store"
  default     = null
}

variable "rancher_insecure" {
  type        = bool
  description = "Skip TLS verification of the Rancher server"
  default     = false
}

# --- Vault --------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "Default AWS region (config/globals/aws.tfvars); used for the etcd S3 cloud credential unless set there"
  default     = null
}

# --- Cluster ------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Name of the downstream cluster in Rancher"
}

variable "fleet_namespace" {
  type        = string
  description = "Fleet namespace of the cluster"
  default     = "fleet-default"
}

variable "kubernetes_version" {
  type        = string
  description = "RKE2 version of the cluster, e.g. v1.33.5+rke2r1"
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable Rancher project network isolation; null leaves the Rancher default"
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Labels of the cluster object"
  default     = {}
}

variable "annotations" {
  type        = map(string)
  description = "Annotations of the cluster object"
  default     = {}
}

variable "pod_security_admission_template" {
  type        = string
  description = "Name of the default Pod Security Admission configuration template (e.g. rancher-restricted)"
  default     = null
}

variable "machine_global_config" {
  type        = any
  description = "RKE2 config applied to all nodes (machineGlobalConfig), e.g. { cni = \"canal\" }"
  default     = null
}

variable "machine_selector_config" {
  type = list(object({
    config       = optional(any)
    match_labels = optional(map(string))
  }))
  description = "RKE2 config applied to nodes matching a label selector (machineSelectorConfig)"
  default     = []
}

variable "chart_values" {
  type        = any
  description = "Values for the RKE2 system charts (chartValues), keyed by chart name"
  default     = null
}

variable "additional_manifest" {
  type        = string
  description = "Additional manifest deployed to the cluster by RKE2"
  default     = null
}

variable "local_auth_endpoint" {
  type = object({
    enabled  = optional(bool, true)
    fqdn     = optional(string)
    ca_certs = optional(string)
    # Only for the kube_config output (not sent to Rancher): API server URL the platform units use
    # directly, e.g. https://<control plane IP>:6443
    server = optional(string)
  })
  description = "Authorized cluster endpoint (direct access to the downstream API server, bypassing Rancher)"
  default     = null
}

variable "upgrade_strategy" {
  type = object({
    control_plane_concurrency = optional(string, "1")
    worker_concurrency        = optional(string, "1")
    control_plane_drain = optional(object({
      enabled                              = optional(bool, false)
      force                                = optional(bool, false)
      ignore_daemon_sets                   = optional(bool, true)
      delete_empty_dir_data                = optional(bool, true)
      disable_eviction                     = optional(bool, false)
      grace_period                         = optional(number, -1)
      timeout                              = optional(number, 120)
      skip_wait_for_delete_timeout_seconds = optional(number, 0)
    }), {})
    worker_drain = optional(object({
      enabled                              = optional(bool, false)
      force                                = optional(bool, false)
      ignore_daemon_sets                   = optional(bool, true)
      delete_empty_dir_data                = optional(bool, true)
      disable_eviction                     = optional(bool, false)
      grace_period                         = optional(number, -1)
      timeout                              = optional(number, 120)
      skip_wait_for_delete_timeout_seconds = optional(number, 0)
    }), {})
  })
  description = "Upgrade strategy of the cluster; defaults match the Rancher defaults"
  default     = {}
}

variable "etcd" {
  type = object({
    disable_snapshots      = optional(bool, false)
    snapshot_schedule_cron = optional(string, "0 */5 * * *")
    snapshot_retention     = optional(number, 5)
    s3 = optional(object({
      bucket                = string
      endpoint              = optional(string, "")
      region                = optional(string)
      folder                = optional(string)
      cloud_credential_name = optional(string) # ignored when etcd_s3_credential is set
      endpoint_ca           = optional(string)
      skip_ssl_verify       = optional(bool, false)
    }))
  })
  description = "etcd snapshot configuration, optionally with an S3 target"
  default     = {}
}

variable "rotate_certificates_generation" {
  type        = number
  description = "Generation of the certificate rotation; increase by one to rotate the cluster certificates"
  default     = null
}

variable "etcd_s3_credential" {
  type = object({
    name                    = string
    description             = optional(string)
    driver                  = optional(string, "s3")
    region                  = optional(string)
    secret_store            = optional(string, "vault") # ClusterSecretStore on the local cluster
    vault_path              = string                    # path below the store's KV mount
    refresh_interval        = optional(string, "15m")
    access_key_id_field     = optional(string, "access_key_id")
    secret_access_key_field = optional(string, "secret_access_key")
  })
  description = "Rancher cloud credential for the etcd S3 target, managed by this module; keys come from Vault via an ExternalSecret on the local cluster (never in state). null keeps etcd.s3.cloud_credential_name"
  default     = null

  validation {
    condition     = var.etcd_s3_credential == null || contains(["s3", "amazonec2"], try(var.etcd_s3_credential.driver, ""))
    error_message = "etcd_s3_credential.driver must be \"s3\" or \"amazonec2\"."
  }
}

variable "registration_token_name" {
  type        = string
  default     = "node-registration"
  description = "Name of the cluster registration token created for node_command (see output registration_token_hashes)"

  validation {
    condition     = var.registration_token_name != "default-token"
    error_message = "default-token is maintained by Rancher (cluster agent) and cannot register custom machines."
  }
}

variable "agent_tolerations" {
  type = list(object({
    key      = string
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = string
  }))
  default     = []
  description = "Additional tolerations of cattle-cluster-agent and fleet-agent"
}

variable "kube_config_token_ttl_seconds" {
  type        = number
  description = "TTL of the token in the direct kubeconfig (seconds, 0 = Rancher's maximum)"
  default     = 0
}

variable "oidc_kubeconfig" {
  type = object({
    issuer_url = string
    client_id  = string
    # Extra arguments of `kubectl oidc-login get-token`, e.g. --listen-address
    extra_args = optional(list(string), [])
  })
  description = "Builds the kube_config_oidc output: direct API endpoint + kubelogin exec (no secret). The API server's OIDC flags are set in machine_global_config. null = no output"
  default     = null
}

variable "cluster_agent_customization" {
  type = object({
    # JSON of a corev1.Affinity; replaces Rancher's default, which *prefers* control-plane nodes (a small
    # control plane then carries both cattle-cluster-agent replicas)
    override_affinity = optional(string)
    resources = optional(object({
      cpu_request    = optional(string)
      cpu_limit      = optional(string)
      memory_request = optional(string)
      memory_limit   = optional(string)
    }))
  })
  description = "cattle-cluster-agent deployment customization (affinity, resources); tolerations: agent_tolerations"
  default     = null
}

variable "fleet_agent_customization" {
  type = object({
    # JSON of a corev1.Affinity; replaces Rancher's default
    override_affinity = optional(string)
    resources = optional(object({
      cpu_request    = optional(string)
      cpu_limit      = optional(string)
      memory_request = optional(string)
      memory_limit   = optional(string)
    }))
  })
  description = "fleet-agent deployment customization (affinity, resources); tolerations: agent_tolerations"
  default     = null
}
