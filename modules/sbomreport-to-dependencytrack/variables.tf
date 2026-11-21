variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "sbomreport-to-dependencytrack chart version (https://takumakume.github.io/sbomreport-to-dependencytrack/charts)"
}

variable "namespace" {
  type        = string
  default     = "dependency-track"
  description = "Namespace (exists – apps/dependency-track)"
}

variable "dependency_track_url" {
  type        = string
  default     = "http://dependency-track-api-server.dependency-track.svc:8080"
  description = "In-cluster URL of the Dependency-Track api-server"
}

variable "parent_project_name" {
  type        = string
  default     = "cluster dreitier"
  description = "Parent project of all image projects – must exist in Dependency-Track (created by hand)"
}

variable "api_key_kv_name" {
  type        = string
  default     = "k8s/prod/dependency-track-sbomreport"
  description = "OpenBao entry with the API key of the Dependency-Track team trivy-operator (property api_key)"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "resources" {
  type        = any
  description = "Kubernetes resources"
  default     = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } }
}
