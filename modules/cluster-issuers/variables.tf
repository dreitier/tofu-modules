variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "acme_email" {
  type = string
}

variable "acme_server" {
  type    = string
  default = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "public_ingress_class" {
  type        = string
  default     = "traefik"
  description = "IngressClass of the public Traefik (http-01 solver)"
}

variable "route53_hosted_zone_id" {
  type        = string
  default     = null
  description = "ACME delegation zone (aws/route53-acme); credentials are ambient (IRSA on the cert-manager controller)"
}

variable "issuers" {
  type        = set(string)
  default     = ["letsencrypt-prod", "letsencrypt-prod-dns"]
  description = "ClusterIssuers to create (letsencrypt-prod-dns needs route53_hosted_zone_id and IRSA)"
}
