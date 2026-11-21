variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "gha-runner-scale-set chart version (same as the controller's)"
}

variable "namespace" {
  type        = string
  description = "Namespace of the scale sets (output runners_namespace of platform/arc-controller)"
}

variable "controller_service_account" {
  type = object({
    namespace = string
    name      = string
  })
  description = "Service account of the controller (output of platform/arc-controller)"
}

variable "github_config_url" {
  type        = string
  description = "Repository whose workflows the runners serve"
}

variable "github_app_kv_name" {
  type        = string
  default     = "k8s/prod/arc-github-app"
  description = "OpenBao entry of the ARC GitHub App (app_id, installation_id, private_key)"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "runner_image" {
  type        = string
  description = "Runner image (ghcr.io/dreitier/actions-runner-tofu)"
}

variable "scale_sets" {
  type = map(object({
    max_runners = optional(number, 1)
  }))
  default     = { plan = {}, apply = {} }
  description = "plan and/or apply – the key decides the rights (read-only / tofu-app)"

  validation {
    condition     = alltrue([for k in keys(var.scale_sets) : contains(["plan", "apply"], k)])
    error_message = "scale_sets: keys plan and apply only."
  }
}

variable "app_namespaces" {
  type        = list(string)
  description = "Namespaces of the automated apps (they must exist – created by the apps' first manual apply)"
}

variable "runner_resources" {
  type    = any
  default = { requests = { cpu = "100m", memory = "512Mi" }, limits = { memory = "2Gi" } }
}
