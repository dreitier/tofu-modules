variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "db"
}

variable "cluster_name" {
  type        = string
  default     = "pg"
  description = "CNPG cluster name (also its service account → IRSA trust)"
}

variable "instances" {
  type    = number
  default = 1
}

variable "image" {
  type        = string
  description = "PostgreSQL image (ghcr.io/cloudnative-pg/postgresql, pinned)"
}

variable "storage_class" {
  type    = string
  default = "nfs-csi"
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}

variable "resources" {
  type = any
  default = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { memory = "1Gi" }
  }
}

variable "secret_store_name" {
  type    = string
  default = "vault"
}

variable "vault_key" {
  type        = string
  default     = "infra/k8s/prod/postgresql"
  description = "Vault KV entry with the role passwords (property user_<role>_pass)"
}

variable "roles" {
  type        = set(string)
  description = "Login roles (passwords from Vault, managed by CNPG; imported at bootstrap)"
}

variable "databases" {
  type = map(object({
    owner      = string
    extensions = optional(list(string), []) # created by CNPG (superuser) – e.g. ltree, pgcrypto
  }))
  description = "Databases (imported at bootstrap, then adopted as Database CRs)"
}

variable "manage_databases" {
  type        = bool
  default     = true
  description = "Create Database CRs (false for the first apply – the import must create them)"
}

variable "import_source" {
  type = object({
    host              = string
    password_property = string
  })
  default     = null
  description = "Instance to import from at bootstrap (monolith, superuser postgres); null = plain initdb"
}

variable "aws_region" {
  type = string
}

variable "backup_role_arn" {
  type = string
}

variable "backup_destination" {
  type        = string
  description = "s3://bucket/prefix for WAL archive and base backups"
}

variable "backup_server_name" {
  type        = string
  default     = null
  description = <<-EOT
    Folder of this cluster below backup_destination (Barman serverName); null = cluster_name. Change it
    together with a PostgreSQL major upgrade: pg_upgrade creates a new system ID and restarts at timeline 1,
    which must not be mixed into the old archive (runbook postgresql.md, "Major upgrade").
  EOT
}

variable "backup_retention" {
  type    = string
  default = "30d"
}

variable "backup_schedule" {
  type        = string
  default     = "0 0 22 * * *"
  description = "Base backup schedule (6 fields, with seconds)"
}

variable "alias_service_name" {
  type        = string
  default     = null
  description = "Service name that points to the cluster's rw service (set after the old release is gone)"
}

variable "monitoring_enabled" {
  type        = bool
  description = "Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
  default     = false
}

variable "role_vault_keys" {
  type        = map(string)
  default     = {}
  description = "OpenBao KV entry per role (property user_<role>_pass) where it differs from vault_key – one entry per generated_secrets version, so adding a role doesn't rotate the others"
}

variable "backup_sidecar_resources" {
  type        = any
  description = "Resources of the Barman Cloud plugin sidecar in the instance pods – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18)"
  default     = { requests = { cpu = "20m", memory = "96Mi" }, limits = { memory = "256Mi" } }
}
