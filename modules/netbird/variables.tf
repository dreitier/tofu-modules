variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "namespace" {
  type    = string
  default = "netbird"
}

variable "domain" {
  type        = string
  description = "Public hostname of NetBird (server and dashboard)"
}

variable "server_image" {
  type        = string
  description = "Combined netbird-server image (management, signal, relay, embedded IdP)"
}

variable "server_args" {
  type        = list(string)
  default     = ["--config", "/etc/netbird/config.yaml"]
  description = "Arguments of netbird-server (config file path)"
}

variable "dashboard_image" {
  type = string
}

variable "stun_uris" {
  type        = list(string)
  description = "External STUN servers (coturn on the gateway), e.g. stun:<ip>:3478 – disables the local STUN"
}

variable "local_auth_disabled" {
  type        = bool
  default     = false
  description = "true once an IdP user is Owner and the Keycloak connector works (docs/netbird.md runbook)"
}

variable "owner_email" {
  type        = string
  description = "Initial local owner (created on the first start; password from OpenBao)"
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "trusted_proxies" {
  type        = list(string)
  default     = ["10.42.0.0/16"]
  description = "CIDRs of the reverse proxies (Traefik pods) – X-Forwarded-For is trusted from them"
}

variable "ingress_class" {
  type    = string
  default = "traefik"
}

variable "cluster_issuer" {
  type    = string
  default = "letsencrypt-prod"
}

variable "storage_class" {
  type    = string
  default = "hcloud-volumes"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "secrets_kv_name" {
  type        = string
  default     = "k8s/prod/netbird"
  description = "OpenBao entry of scripts/netbird-secrets.sh (store_encryption_key, relay_auth_secret, idp_cookie_key, owner_password)"
}

variable "db_host" {
  type    = string
  default = "pg-rw.db.svc"
}

variable "db_user" {
  type    = string
  default = "netbird"
}

variable "db_kv_name" {
  type    = string
  default = "k8s/prod/postgresql-netbird"
}

variable "db_kv_property" {
  type    = string
  default = "user_netbird_pass"
}

variable "resources" {
  type = object({
    server = object({
      requests = map(string)
      limits   = map(string)
    })
    dashboard = object({
      requests = map(string)
      limits   = map(string)
    })
  })
  default = {
    server    = { requests = { cpu = "100m", memory = "256Mi" }, limits = { memory = "1Gi" } }
    dashboard = { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } }
  }
}

variable "trusted_peers" {
  type        = list(string)
  default     = ["100.64.0.0/10"]
  description = "NetBird peer networks whose X-Forwarded-For is trusted (unset = 0.0.0.0/0)"
}
