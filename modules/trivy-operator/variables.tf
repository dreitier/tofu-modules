variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "trivy-operator chart version (https://aquasecurity.github.io/helm-charts/)"
}

variable "namespace" {
  type    = string
  default = "trivy-system"
}

variable "excluded_namespaces" {
  type        = list(string)
  description = "Namespaces (glob patterns allowed) that are not scanned"
  default     = []
}

variable "scan_jobs_concurrent_limit" {
  type        = number
  description = "Parallel scan jobs (2 workers – keep it low)"
  default     = 3
}

variable "compliance_specs" {
  type        = list(string)
  description = "Cluster compliance reports (every 6 h)"
  default     = ["rke2-cis-1.24", "k8s-nsa-1.0", "k8s-pss-baseline-0.1", "k8s-pss-restricted-0.1"]
}

variable "storage_class" {
  type    = string
  default = "hcloud-volumes"
}

variable "storage_size" {
  type        = string
  description = "Volume of the built-in Trivy server (vulnerability DB + cache)"
  default     = "5Gi"
}

variable "resources" {
  type = object({
    operator     = optional(any, { requests = { cpu = "100m", memory = "512Mi" }, limits = { memory = "1Gi" } })
    trivy_server = optional(any, { requests = { cpu = "200m", memory = "512Mi" }, limits = { memory = "1Gi" } })
    scan_job     = optional(any, { requests = { cpu = "100m", memory = "100M" }, limits = { memory = "500M" } })
  })
  description = "Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key trivy_operator)"
  default     = {}
}

variable "webhook_url" {
  type        = string
  default     = null
  description = "Report webhook (apps/sbomreport-to-dependencytrack output webhook_url); null = none"
}

variable "monitoring_enabled" {
  type        = bool
  description = "ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com)"
  default     = false
}
