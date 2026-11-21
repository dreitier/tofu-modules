variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "psono"
}

variable "chart_version" {
  type = string
}

variable "hostname" {
  type        = string
  description = "Internal hostname (VPN), e.g. passwords.intern.<domain>"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "user_domain" {
  type        = string
  description = "Domain part of the Psono usernames (= the users' UPN domain)"
}

variable "keycloak_url" {
  type = string
}

variable "keycloak_realm" {
  type = string
}

variable "oidc_client_id" {
  type    = string
  default = "psono"
}

variable "oidc_title" {
  type    = string
  default = "dreitier"
}

variable "oidc_button" {
  type    = string
  default = "Anmelden mit Microsoft"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "keys_kv_name" {
  type    = string
  default = "k8s/prod/psono"
}

variable "oidc_kv_name" {
  type    = string
  default = "k8s/prod/oidc/psono"
}

variable "db_host" {
  type    = string
  default = "pg-rw.db.svc"
}

variable "db_name" {
  type    = string
  default = "psono"
}

variable "db_user" {
  type    = string
  default = "psono"
}

variable "db_kv_name" {
  type    = string
  default = "k8s/prod/postgresql-psono"
}

variable "db_kv_property" {
  type    = string
  default = "user_psono_pass"
}

variable "resources" {
  type = any
  default = {
    requests = { cpu = "100m", memory = "1Gi" }
    limits   = { memory = "1536Mi" }
  }
}

# Fileserver (attachments) with one amazon_s3 shard via IRSA. null = no fileserver (and files disabled in
# the web client). Keys: scripts/psono-fileserver-keys.sh → OpenBao <keys_kv_name> (PSONOFS_*), which
# also prints cluster_id/shard_id/server_public_key (not secret) for these inputs.
variable "fileserver" {
  type = object({
    hostname          = string # e.g. psono-files.intern.<domain> (wildcard certificate, dnsmasq)
    shard_id          = string # from the keys script
    server_public_key = string # the server's PSONO_PUBLIC_KEY (public)
    bucket            = string # S3 bucket of the shard
    role_arn          = string # IRSA role (aws/irsa-prod prod-psono-fileserver)
    aws_region        = optional(string, "eu-central-1")
    keys_kv_name      = optional(string, "k8s/prod/psono-fileserver")
    resources = optional(any, {
      requests = { cpu = "50m", memory = "256Mi" }
      limits   = { memory = "512Mi" }
    })
  })
  default = null
}

variable "smtp_host" {
  type        = string
  default     = "localhost"
  description = "SMTP relay (platform/mail-relay output smtp_host), port 25 without auth"
}

variable "cleanup_resources" {
  type        = any
  description = "Cron job cleartoken (manage.py in the server image) – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18)"
  default     = { requests = { cpu = "10m", memory = "128Mi" }, limits = { memory = "256Mi" } }
}
