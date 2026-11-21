variable "kube_config" {
  type        = string
  sensitive   = true
  default     = null
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit); null = in-cluster service account (CI)"
}

variable "namespace" {
  type    = string
  default = "fintier"
}

variable "image" {
  type        = string
  description = "Image incl. tag, e.g. ghcr.io/dreitier/fintier:2.0.0 (private package → pull secret)"
}

variable "hostname" {
  type        = string
  description = "Internal hostname (VPN), e.g. fintier.intern.<domain>"
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
  default = "fintier"
}

variable "oidc_label" {
  type        = string
  default     = "dreitier-Konto"
  description = "Text of the SSO button (\"Anmelden mit …\")"
}

variable "access_group" {
  type        = string
  description = "Keycloak group (name in the groups claim) whose members may use fintier – same as the client's access_groups in config/keycloak"
}

variable "local_login" {
  type        = bool
  default     = true
  description = "Break-glass login with local users (created with python -m app.cli create-user); without such users the form is inert"
}

variable "secret_store_name" {
  type    = string
  default = "openbao"
}

variable "keys_kv_name" {
  type        = string
  default     = "k8s/prod/fintier"
  description = "OpenBao entry with data_key and session_key (scripts/fintier-keys.sh, write once)"
}

variable "oidc_kv_name" {
  type    = string
  default = "k8s/prod/oidc/fintier"
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

# database and role are named fintier in the application (not configurable there)
variable "db_user" {
  type    = string
  default = "fintier"
}

variable "db_kv_name" {
  type    = string
  default = "k8s/prod/postgresql-fintier"
}

variable "resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  # pdfplumber parses whole PDFs in memory
  default = {
    requests = { cpu = "50m", memory = "256Mi" }
    limits   = { memory = "768Mi" }
  }
}
