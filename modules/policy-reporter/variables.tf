variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "Policy Reporter chart version (oci://ghcr.io/kyverno/charts/policy-reporter)"
}

variable "namespace" {
  type    = string
  default = "policy-reporter"
}

variable "internal_domain" {
  type        = string
  description = "Internal (VPN) domain – UI at policy-reporter.<internal_domain>"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "keycloak_url" {
  type        = string
  description = "Keycloak base URL, e.g. https://idp.dreitier.com"
}

variable "keycloak_realm" {
  type    = string
  default = "dreitier"
}

variable "oidc_kv_name" {
  type        = string
  default     = "k8s/prod/oidc/policy-reporter"
  description = "Keycloak client secret (config/keycloak, client policy-reporter: client_id, client_secret)"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "resources" {
  type = object({
    core           = optional(any, { requests = { cpu = "20m", memory = "64Mi" }, limits = { memory = "256Mi" } })
    ui             = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })
    kyverno_plugin = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })
  })
  description = "Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key policy_reporter)"
  default     = {}
}

variable "monitoring_enabled" {
  type        = bool
  description = "ServiceMonitor and Grafana dashboards – needs the Prometheus Operator CRDs (monitoring.coreos.com)"
  default     = false
}
