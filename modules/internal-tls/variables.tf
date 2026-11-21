variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type        = string
  default     = "traefik-internal"
  description = "Namespace of the internal Traefik"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "internal_domain" {
  type = string
}

variable "issuer" {
  type    = string
  default = "letsencrypt-prod-dns"
}
