variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "cnpg-system"
}

variable "operator_chart_version" {
  type = string
}

variable "barman_cloud_chart_version" {
  type = string
}

variable "monitoring_enabled" {
  type        = bool
  description = "Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
  default     = false
}

variable "resources" {
  type = object({
    operator     = optional(any, { requests = { cpu = "50m", memory = "96Mi" }, limits = { memory = "256Mi" } })
    barman_cloud = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })
  })
  description = "Operator and Barman Cloud plugin – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18)"
  default     = {}
}
