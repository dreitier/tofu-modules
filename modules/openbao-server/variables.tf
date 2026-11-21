variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "openbao"
}

variable "chart_version" {
  type = string
}

variable "replicas" {
  type    = number
  default = 3
}

variable "hostname" {
  type        = string
  description = "Internal hostname (VPN only)"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "storage_class" {
  type    = string
  default = "hcloud-volumes"
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}

variable "aws_region" {
  type = string
}

variable "kms_key_id" {
  type        = string
  description = "KMS key (alias) for auto-unseal (aws/kms-<cluster>-openbao-unseal)"
}

variable "kms_plugin_image" {
  type        = string
  description = "OCI image of the AWS KMS seal plugin, pinned by digest (ghcr.io/openbao/openbao-plugin-kms-aws:<tag>@sha256:<digest>)"

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.kms_plugin_image))
    error_message = "kms_plugin_image must be pinned by digest (…@sha256:<64 hex>)."
  }
}

variable "irsa_role_arn" {
  type        = string
  description = "IAM role of the service account openbao/openbao (aws/irsa-<cluster>)"
}

variable "admin_service_account" {
  type        = string
  description = "Service account bound to the self-init admin role (kubernetes auth, mount kubernetes-admin). Fixed at first start."
  default     = "openbao-admin"
}

variable "resources" {
  type = any
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { memory = "512Mi" }
  }
}

variable "anti_affinity_required" {
  type        = bool
  description = "Hard pod anti-affinity (one OpenBao pod per node). false = preference only, for clusters with fewer worker nodes than replicas."
  default     = true
}

variable "snapshot" {
  type = object({
    bucket        = string
    role_arn      = string # IRSA role of the service account openbao/openbao-snapshot (PutObject on the bucket)
    schedule      = optional(string, "15 */6 * * *")
    prefix        = optional(string, "openbao")
    auth_mount    = optional(string, "kubernetes") # config/openbao-base
    auth_role     = optional(string, "openbao-snapshot")
    openbao_image = string # bao CLI, same version as the server
    aws_cli_image = string
  })
  default     = null
  description = "Raft snapshots to S3 by CronJob; null = off"
}

variable "monitoring_enabled" {
  type        = bool
  default     = false
  description = "Prometheus metrics: telemetry in the server config (unauthenticated /v1/sys/metrics) + ServiceMonitor – needs the Prometheus Operator CRDs. Changing it restarts the pods (rolling, auto-unseal)."
}

variable "snapshot_resources" {
  type = object({
    snapshot = optional(object({ requests = map(string), limits = map(string) }), { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "64Mi" } })
    upload   = optional(object({ requests = map(string), limits = map(string) }), { requests = { cpu = "20m", memory = "128Mi" }, limits = { memory = "256Mi" } }) # aws-cli (Python)
  })
  description = "Raft snapshot CronJob: init container (bao) and upload (aws-cli) – every container needs requests + a memory limit (Kyverno require-requests-limits)"
  default     = {}
}
