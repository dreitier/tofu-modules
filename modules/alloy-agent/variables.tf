variable "openbao_url" {
  type = string
}

variable "openbao_auth_method" {
  type    = string
  default = "oidc"
  # token: no login block – the provider uses VAULT_TOKEN (or ~/.vault-token), e.g. from `bao login`

  validation {
    condition     = contains(["oidc", "kubernetes", "token"], var.openbao_auth_method)
    error_message = "openbao_auth_method must be oidc, kubernetes or token."
  }
}

variable "openbao_oidc_role" {
  type    = string
  default = "admin"
}

variable "openbao_jwt" {
  type      = string
  sensitive = true
  default   = ""
}

variable "kv_mount" {
  type    = string
  default = "infra"
}

variable "rancher_url" {
  type        = string
  description = "Rancher server URL (config/globals/kubernetes.tfvars)"
}

variable "rancher_token_kv_name" {
  type        = string
  default     = "tofu/rancher"
  description = "OpenBao entry with key token: API key (no scope) of the Rancher local user opentofu"
}

variable "cluster_label" {
  type        = string
  description = "Value of the `cluster` label on all metrics and logs"
}

variable "prometheus_url" {
  type        = string
  description = "Base URL of the central Prometheus (remote write receiver), e.g. https://prometheus.intern.<domain>"
}

variable "loki_url" {
  type        = string
  description = "Base URL of the central Loki, e.g. https://loki.intern.<domain>"
}

variable "namespace" {
  type    = string
  default = "alloy"
}

variable "k8s_monitoring_version" {
  type = string
}

variable "resources" {
  type = object({
    alloy_logs      = any
    alloy_singleton = any
  })
  default = {
    alloy_logs      = { requests = { cpu = "50m", memory = "128Mi" }, limits = { memory = "512Mi" } }
    alloy_singleton = { requests = { cpu = "50m", memory = "256Mi" }, limits = { memory = "1Gi" } }
  }
}

variable "pod_log_processing_stages" {
  type        = string
  default     = ""
  description = "Alloy stage blocks for pod logs (k8s-monitoring podLogsViaLoki.extraLogProcessingStages), e.g. config/alloy/traefik-logs.alloy"
}

variable "geoip_init" {
  type = object({
    image  = string
    script = string
  })
  default     = null
  description = "Init container of alloy-logs that downloads the GeoIP database into /geoip (emptyDir), e.g. config/alloy/geoip-download.sh; required when the pod-log stages include config/alloy/traefik-geoip.alloy. null = no GeoIP"
}
