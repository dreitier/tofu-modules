variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "name" {
  type = string
}

variable "hostname" {
  type        = string
  description = "Rancher hostname (server URL), e.g. rancher.intern.example.com – resolves to private_ip"
}

variable "server_type" {
  type    = string
  default = "cpx32"
}

variable "image" {
  type    = string
  default = "rocky-9"
}

variable "location" {
  type = string
}

variable "ssh_key_ids" {
  type    = list(string)
  default = []
}

variable "network_id" {
  type = string
}

variable "network_router_ip" {
  type        = string
  description = "Hetzner's router in the network (first IP of the network range)"
}

variable "private_ip" {
  type = string
}

variable "k3s_version" {
  type        = string
  description = "k3s release (e.g. v1.33.x+k3s1) – must be in the support matrix of rancher_version"

  validation {
    condition     = can(regex("^v1\\.[0-9]+\\.[0-9]+\\+k3s[0-9]+$", var.k3s_version))
    error_message = "k3s_version must be a pinned release like v1.33.5+k3s1."
  }
}

variable "rancher_version" {
  type        = string
  description = "Rancher chart version (stable repo)"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.rancher_version))
    error_message = "rancher_version must be a pinned chart version like 2.12.3."
  }
}

variable "cert_manager_version" {
  type        = string
  description = "cert-manager chart version (vX.Y.Z), supported by rancher_version"
}

variable "protect" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "gateway_ip" {
  type        = string
  description = "Private IP of the gateway: DNS resolver (dnsmasq) of the server (config/globals/hetzner.tfvars)"
}

variable "letsencrypt_manifest" {
  type        = string
  description = "ClusterIssuer + Certificate for the Rancher ingress (config/rancher/letsencrypt.yaml), applied by k3s"
}

variable "cacerts_pem" {
  type        = string
  description = "Rancher's cacerts (Let's Encrypt roots, config/ca/rancher-ca.pem) for the Secret tls-ca"
}
