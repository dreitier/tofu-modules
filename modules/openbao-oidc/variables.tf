# Login of the vault provider (set by terragrunt-backend.hcl for every unit)
variable "openbao_url" {
  type        = string
  description = "OpenBao URL as seen from the workstation (via VPN)"
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
  type        = string
  sensitive   = true
  default     = ""
  description = "Service account token for openbao_auth_method = kubernetes (kubectl -n openbao create token openbao-admin)"
}


variable "keycloak_url" {
  type        = string
  description = "Keycloak base URL (Keycloak >= 17: without /auth)"
}

# Login at Keycloak's master realm (env BASEMENT_KEYCLOAK_AUTH via terragrunt-backend.hcl):
#   client_credentials (default) – service account client "opentofu" (created by config/keycloak, secret in
#                                  OpenBao infra/tofu/keycloak)
#   password                     – a master admin user (admin-cli password grant): only the very first run of
#                                  config/keycloak on a fresh Keycloak (bootstrap admin) and break-glass
variable "keycloak_auth_method" {
  type    = string
  default = "client_credentials"

  validation {
    condition     = contains(["client_credentials", "password"], var.keycloak_auth_method)
    error_message = "keycloak_auth_method must be client_credentials or password."
  }
}

variable "keycloak_tofu_kv_mount" {
  type    = string
  default = "infra"
}

variable "keycloak_tofu_kv_name" {
  type        = string
  default     = "tofu/keycloak"
  description = "OpenBao entry of the service account client (client_id, client_secret)"
}

variable "keycloak_admin_user" {
  type        = string
  default     = "admin"
  description = "Master admin for keycloak_auth_method = password (bootstrap admin, or a temporary break-glass admin)"
}

variable "keycloak_admin_kv_mount" {
  type    = string
  default = "infra"
}

variable "keycloak_admin_kv_name" {
  type    = string
  default = "k8s/prod/keycloak"
}

variable "keycloak_admin_password_key" {
  type    = string
  default = "user_admin_pass"
}

variable "keycloak_realm" {
  type        = string
  description = "Realm that holds the OpenBao client"
}

variable "oidc_client_id" {
  type    = string
  default = "openbao"
}

variable "oidc_client_secret_version" {
  type        = number
  default     = 1
  description = "Bump to rotate the OIDC client secret (written write-only to Keycloak and OpenBao)"
}

variable "oidc_roles" {
  type = map(object({
    bound_groups          = list(string)
    token_policies        = list(string)
    token_ttl             = optional(number, 3600)
    allowed_redirect_uris = list(string)
  }))
  description = "OIDC roles (key = role name); bound to the Keycloak groups claim"
}

variable "oidc_default_role" {
  type = string
}
