variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "Kyverno chart version (oci://ghcr.io/kyverno/charts/kyverno; 3.10.x = Kyverno 1.20.x)"
}

variable "namespace" {
  type    = string
  default = "kyverno"
}

variable "admission_replicas" {
  type        = number
  description = "Replicas of the admission controller (>1 also creates a PDB)"
  default     = 2
}

variable "webhook_excluded_namespaces" {
  type        = list(string)
  description = "Namespaces the Kyverno webhooks never see (the kyverno namespace is excluded by the chart anyway)"
  default     = ["kube-system"]
}

variable "resources" {
  type = object({
    admission_controller  = optional(any, { requests = { cpu = "100m", memory = "128Mi" }, limits = { memory = "384Mi" } })
    background_controller = optional(any, { requests = { cpu = "100m", memory = "64Mi" }, limits = { memory = "128Mi" } })
    cleanup_controller    = optional(any, { requests = { cpu = "100m", memory = "64Mi" }, limits = { memory = "128Mi" } })
    reports_controller    = optional(any, { requests = { cpu = "100m", memory = "128Mi" }, limits = { memory = "256Mi" } })
  })
  description = "Kubernetes resources per controller – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key kyverno)"
  default     = {}
}

variable "monitoring_enabled" {
  type        = bool
  description = "ServiceMonitors, PrometheusRule and Grafana dashboard – needs the Prometheus Operator CRDs (monitoring.coreos.com)"
  default     = false
}
