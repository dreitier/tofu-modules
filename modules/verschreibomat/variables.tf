variable "kube_config" {
  type        = string
  sensitive   = true
  default     = null
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit); null = in-cluster service account (CI)"
}

variable "namespace" {
  type    = string
  default = "verschreibomat"
}

variable "image" {
  type        = string
  description = "Image incl. tag, e.g. ghcr.io/dreitier/verschreibomat:1.0.0 (private package → pull secret)"
}

variable "hostname" {
  type        = string
  description = "Internal hostname (VPN), e.g. verschreibomat.intern.<domain>"
}

variable "ingress_class" {
  type    = string
  default = "traefik-internal"
}

variable "keycloak_url" {
  type = string
}

variable "keycloak_realm" {
  type = string
}

variable "oidc_client_id" {
  type    = string
  default = "verschreibomat"
}

variable "moco_base_url" {
  type        = string
  default     = "https://dreitier.mocoapp.com/api/v1"
  description = "API base URL of the Moco account"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "keys_kv_name" {
  type        = string
  default     = "k8s/prod/verschreibomat"
  description = "OpenBao entry with the encryption keys encryption_key_<id> (scripts/verschreibomat-keys.sh)"
}

variable "encryption_key_ids" {
  type        = list(string)
  default     = ["k1"]
  description = "Ids of all encryption keys in keys_kv_name; old ids stay until no row uses them (README of verschreibomat)"
}

variable "encryption_active_key" {
  type        = string
  default     = "k1"
  description = "Id the application encrypts new values with"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.encryption_active_key))
    error_message = "Key ids: lower-case letters and digits."
  }
}

variable "oidc_kv_name" {
  type    = string
  default = "k8s/prod/oidc/verschreibomat"
}

variable "pull_kv_name" {
  type        = string
  default     = "k8s/prod/ghcr-pull"
  description = "OpenBao entry with username + token (classic PAT, read:packages) for ghcr.io"
}

variable "db_host" {
  type    = string
  default = "pg-rw.db.svc"
}

variable "db_name" {
  type    = string
  default = "verschreibomat"
}

variable "db_user" {
  type    = string
  default = "verschreibomat"
}

variable "db_kv_name" {
  type    = string
  default = "k8s/prod/postgresql-verschreibomat"
}

variable "resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "100m", memory = "512Mi" }
    limits   = { memory = "768Mi" }
  }
}

variable "monitoring_enabled" {
  type        = bool
  description = "Create the ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster"
  default     = false
}
