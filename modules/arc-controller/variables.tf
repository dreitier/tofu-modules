variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "gha-runner-scale-set-controller chart version (oci://ghcr.io/actions/actions-runner-controller-charts)"
}

variable "namespace" {
  type    = string
  default = "arc-systems"
}

variable "controller_name" {
  type        = string
  default     = "arc-controller"
  description = "Release fullname and service account of the controller (referenced by the scale sets)"
}

variable "watch_namespace" {
  type        = string
  default     = "arc-runners"
  description = "Namespace of the runner scale sets (created here, used by platform/arc-runners)"
}

variable "resources" {
  type    = any
  default = { requests = { cpu = "20m", memory = "64Mi" }, limits = { memory = "256Mi" } }
}
