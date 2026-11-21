variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "chart_version" {
  type = string
}

variable "network_name" {
  type        = string
  description = "Private network (output network_name of hetzner/<env>/network)"
}

variable "cluster_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "location" {
  type        = string
  description = "Default location of the load balancers"
}

variable "token_revision" {
  type        = number
  default     = 1
  description = "Bump after rotating hcloud_token in SOPS (write-only data is only re-sent on a new revision)"
}
