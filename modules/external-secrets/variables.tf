variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "external-secrets chart version (keep the deployed one for the import, upgrade separately)"
}

variable "namespace" {
  type    = string
  default = "external-secrets"
}

variable "ca_bundle_pem" {
  type        = string
  default     = null
  description = "Additional CA (PEM) trusted by the operator, e.g. for Vault behind a FreeIPA certificate"
}

variable "resources" {
  type = object({
    controller      = optional(any, { requests = { cpu = "10m", memory = "64Mi" }, limits = { memory = "128Mi" } })
    cert_controller = optional(any, { requests = { cpu = "10m", memory = "96Mi" }, limits = { memory = "192Mi" } })
    webhook         = optional(any, { requests = { cpu = "10m", memory = "48Mi" }, limits = { memory = "96Mi" } })
  })
  description = "every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18)"
  default     = {}
}
