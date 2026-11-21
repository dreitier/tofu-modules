variable "kube_config" {
  type      = string
  sensitive = true
}

variable "cluster_label" {
  type        = string
  description = "Value of the `cluster` label on all metrics and logs"
}

variable "internal_domain" {
  type        = string
  description = "Domain of the internal ingresses (grafana.<domain>)"
}

variable "keycloak_url" {
  type        = string
  description = "Base URL of Keycloak (https://idp.<domain>)"
}

variable "keycloak_realm" {
  type    = string
  default = "dreitier"
}

variable "grafana_admin_group" {
  type        = string
  default     = "infrastruktur_SG"
  description = "Keycloak group (groups claim) that becomes Grafana admin; Keycloak already limits the client to it"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "namespaces" {
  type = object({
    monitoring = string
    loki       = string
    alloy      = string
  })
  default = {
    monitoring = "monitoring"
    loki       = "loki"
    alloy      = "alloy"
  }
}

# --- Chart versions ------------------------------------------------------------------------------

variable "kube_prometheus_stack_version" {
  type = string
}

variable "blackbox_exporter_version" {
  type = string
}

variable "grafana_version" {
  type = string
}

variable "loki_version" {
  type = string
}

variable "k8s_monitoring_version" {
  type = string
}

# --- Prometheus / Alertmanager -------------------------------------------------------------------

variable "prometheus_retention" {
  type    = string
  default = "30d"
}

variable "prometheus_retention_size" {
  type        = string
  default     = "18GB"
  description = "Safety net below the volume size – oldest blocks go first"
}

variable "prometheus_pvc_size" {
  type    = string
  default = "20Gi"
}

variable "alertmanager_pvc_size" {
  type        = string
  default     = "10Gi"
  description = "hcloud volumes are at least 10 GB"
}

variable "smtp_host" {
  type        = string
  description = "SMTP relay (platform/mail-relay), port 25 without auth and TLS"
}

variable "mail_from" {
  type = string
}

variable "mail_to" {
  type = string
}

variable "blackbox_targets" {
  type        = map(list(string))
  default     = {}
  description = "Blackbox probes: module (manifests/blackbox-modules.yaml) → URLs"
}

# --- Loki ------------------------------------------------------------------------------------------

variable "loki_s3" {
  type = object({
    endpoint = string # https://fsn1.your-objectstorage.com
    region   = string # fsn1
    bucket   = string
    kv_name  = optional(string, "k8s/prod/loki-s3") # access_key, secret_key (Hetzner S3 credentials)
  })
}

variable "loki_retention" {
  type    = string
  default = "30d"
}

variable "loki_pvc_size" {
  type        = string
  default     = "10Gi"
  description = "WAL and index cache of the single-binary Loki (chunks live in the bucket)"
}

# --- Grafana -------------------------------------------------------------------------------------

variable "grafana_admin_kv_name" {
  type        = string
  default     = "k8s/prod/grafana"
  description = "OpenBao entry with user_admin_pass (local break-glass admin, config/openbao-base)"
}

variable "grafana_oidc_kv_name" {
  type        = string
  default     = "k8s/prod/oidc/grafana"
  description = "Keycloak client secret (config/keycloak, client grafana)"
}

variable "grafana_pvc_size" {
  type        = string
  default     = "10Gi"
  description = "SQLite database (users, preferences, annotations); dashboards and datasources are provisioned"
}

variable "resources" {
  type = any
  default = {
    prometheus_operator = { requests = { cpu = "10m", memory = "48Mi" }, limits = { memory = "128Mi" } }
    prometheus          = { requests = { cpu = "100m", memory = "1Gi" }, limits = { memory = "2Gi" } } # 7-day max 1.3 GiB (2026-11-18)
    alertmanager        = { requests = { cpu = "10m", memory = "48Mi" }, limits = { memory = "128Mi" } }
    kube_state_metrics  = { requests = { cpu = "10m", memory = "64Mi" }, limits = { memory = "192Mi" } }
    blackbox_exporter   = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "100Mi" } }
    grafana             = { requests = { cpu = "50m", memory = "384Mi" }, limits = { memory = "1Gi" } } # Grafana 13: search index in memory
    loki                = { requests = { cpu = "50m", memory = "256Mi" }, limits = { memory = "1Gi" } }
    alloy_logs          = { requests = { cpu = "20m", memory = "128Mi" }, limits = { memory = "384Mi" } }
    # Sidecars and helpers – every container needs requests + a memory limit (Kyverno require-requests-limits).
    # Sized from the 7-day maxima in Prometheus (2026-11-18).
    alloy_singleton            = { requests = { cpu = "20m", memory = "128Mi" }, limits = { memory = "1Gi" } } # peaked at ~780 MiB
    alloy_operator             = { requests = { cpu = "10m", memory = "64Mi" }, limits = { memory = "192Mi" } }
    alloy_config_reloader      = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "64Mi" } }
    prometheus_config_reloader = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "64Mi" } }
    grafana_sidecar            = { requests = { cpu = "10m", memory = "96Mi" }, limits = { memory = "192Mi" } }
    grafana_init_chown         = { requests = { cpu = "10m", memory = "16Mi" }, limits = { memory = "32Mi" } }
    loki_sidecar               = { requests = { cpu = "10m", memory = "96Mi" }, limits = { memory = "192Mi" } }
  }
}

variable "heartbeat" {
  type = object({
    kv_name     = string
    kv_property = optional(string, "ping_url")
  })
  default     = null
  description = "External heartbeat for the Watchdog alert (healthchecks.io ping URL in OpenBao); null = Watchdog is dropped"
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
