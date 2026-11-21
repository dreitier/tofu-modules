# Login of the vault provider (set by terragrunt-backend.hcl for every unit)
variable "openbao_url" {
  type = string
}

variable "openbao_auth_method" {
  type    = string
  default = "oidc"
  # token: no login block – the provider uses VAULT_TOKEN (or ~/.vault-token), e.g. from `bao login`

  validation {
    condition     = contains(["oidc", "kubernetes", "token"], var.openbao_auth_method)
    error_message = "openbao_auth_method must be oidc, kubernetes or token."
  }
}

variable "openbao_oidc_role" {
  type    = string
  default = "admin"
}

variable "openbao_jwt" {
  type      = string
  sensitive = true
  default   = ""
}

variable "kv_mount" {
  type    = string
  default = "infra"
}

variable "rancher_url" {
  type        = string
  description = "Rancher server URL (config/globals/kubernetes.tfvars)"
}

variable "rancher_token_kv_name" {
  type        = string
  default     = "tofu/rancher"
  description = "OpenBao entry with key token: API key (no scope) of the Rancher local user opentofu"
}

variable "keycloak_url" {
  type = string
}

variable "keycloak_realm" {
  type    = string
  default = "dreitier"
}

variable "client_id" {
  type    = string
  default = "rancher"
}

variable "oidc_kv_name" {
  type        = string
  default     = "k8s/prod/oidc/rancher"
  description = "OpenBao entry of the Keycloak client (client_secret), written by config/keycloak"
}

variable "client_secret_version" {
  type        = number
  default     = 1
  description = "Bump together with secret_version of the client in config/keycloak to copy a rotated secret into Rancher"
}

variable "access_group" {
  type        = string
  description = "Keycloak group required to log in at all (accessMode required); gets read-only on the clusters"
}

variable "admin_group" {
  type        = string
  description = "Keycloak group that gets Rancher's global role admin (must also be in access_group)"
}

variable "read_only_cluster_ids" {
  type        = list(string)
  description = "Cluster IDs (c-m-…) where access_group gets the role template read_only"
}

variable "read_only_api_groups" {
  type        = list(string)
  description = "API groups readable by the read-only role (all resources); the core group is listed separately without secrets"
}
