variable "kube_config" {
  type        = string
  sensitive   = true
  default     = null
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit); null = in-cluster service account (CI)"
}

variable "namespace" {
  type    = string
  default = "backmon"
}

variable "chart_version" {
  type        = string
  description = "Version of the chart backmon (dreitier/helm-charts)"
}

variable "image" {
  type        = string
  description = "Image incl. tag, e.g. ghcr.io/dreitier/backmon:6.2.1 (public package) – overrides the chart's image"

  validation {
    condition     = can(regex("^(.+):([^:/]+)$", var.image))
    error_message = "image must be <repository>:<tag>."
  }
}

variable "hostname" {
  type        = string
  description = "Internal hostname (VPN), e.g. backmon.intern.<domain>"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "role_arn" {
  type        = string
  description = "IRSA role of the service account <namespace>/backmon (aws/irsa-prod): s3:ListBucket on the buckets, s3:GetObject on their backup_definitions.yaml"
}

variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "Region of the buckets (and of the STS endpoint)"
}

variable "buckets" {
  type        = list(string)
  description = "S3 buckets to monitor (backmon: disks); each needs a backup_definitions.yaml in its root"

  validation {
    condition     = length(var.buckets) > 0
    error_message = "At least one bucket."
  }
}

variable "environment_name" {
  type        = string
  default     = "aws"
  description = "Name of the backmon environment (label environment of the metrics)"
}

variable "update_interval" {
  type        = string
  default     = "15m"
  description = "Interval of the bucket scans"
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "10m", memory = "64Mi" }
    limits   = { memory = "256Mi" }
  }
}

variable "monitoring_enabled" {
  type        = bool
  default     = false
  description = "Create the ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
}

variable "alerts_enabled" {
  type        = bool
  default     = false
  description = "Create the chart's PrometheusRule (backup overdue/missing/size changed, …) – needs monitoring_enabled"
}

variable "alert_rules" {
  type        = any
  default     = {}
  description = "Overrides of the chart's prometheusRules values (per rule: enabled, thresholds), e.g. { backupSizeChanged = { enabled = false } }"
}
