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
  description = "Realm of the app clients"
}

variable "kv_mount" {
  type    = string
  default = "infra"
}

variable "oidc_kv_prefix" {
  type        = string
  default     = "k8s/prod/oidc"
  description = "KV path prefix of the client secrets (one entry per client, read by the apps' ExternalSecrets)"
}

variable "clients" {
  type = map(object({
    client_id                       = optional(string) # default: map key
    name                            = optional(string)
    root_url                        = optional(string)
    base_url                        = optional(string)
    valid_redirect_uris             = list(string)
    valid_post_logout_redirect_uris = optional(list(string), [])
    web_origins                     = optional(list(string), [])
    secret_version                  = optional(number, 1) # bump to rotate (Keycloak + OpenBao)
    # Public client (PKCE S256, no secret, nothing written to OpenBao) – CLI tools such as kubelogin
    public = optional(bool, false)
    # Only members of these Keycloak groups may log in (client role restricted-access, needs
    # restrict_client_auth); null = every user of the realm
    access_groups = optional(list(string))
  }))
  description = "OIDC clients (standard flow) of the apps, confidential unless public = true; key = OpenBao KV entry name"
}

variable "saml_clients" {
  type = map(object({
    entity_id = string # SP entity ID / issuer URL = Keycloak client_id
    acs_url   = string # assertion consumer service URL (HTTP-POST), default when the request names none
    # Further ACS URLs the SP may request (valid redirect URIs), e.g. AWS's IPv4/dual-stack endpoints
    extra_acs_urls = optional(list(string), [])
    name           = optional(string)
    base_url       = optional(string) # SP start page (link in Keycloak's account console)
    # username = UPN (Entra preferred_username, format unspecified), email (format emailAddress, e.g. AWS)
    name_id_format            = optional(string, "username")
    client_signature_required = optional(bool, false) # SP signs its AuthnRequests
    # Like clients.access_groups (restricted-access role, needs restrict_client_auth)
    access_groups = optional(list(string))
  }))
  default     = {}
  description = "SAML clients (service providers); key = name in this module, must not collide with var.clients"

  validation {
    condition     = alltrue([for c in values(var.saml_clients) : contains(["username", "email", "persistent", "transient"], c.name_id_format)])
    error_message = "name_id_format must be username, email, persistent or transient."
  }
}

variable "realm_display_name" {
  type    = string
  default = null
}

variable "groups" {
  type        = set(string)
  default     = []
  description = "Keycloak groups filled from Entra ID (mapper of the entra identity provider)"
}

variable "netbird" {
  type = object({
    dashboard_url       = string
    extra_redirect_uris = optional(list(string), ["http://localhost:53000"])
  })
  default     = null
  description = "NetBird public client; null = not created"
}

variable "entra_tenant_id" {
  type = string
}

variable "entra_client_id" {
  type        = string
  default     = null
  description = "Client ID of the Keycloak app registration (entra/apps); null = no Entra broker"
}

variable "entra_display_name" {
  type    = string
  default = "Microsoft Entra ID"
}

variable "entra_group_ids" {
  type        = map(string)
  default     = {}
  description = "Keycloak group name → Entra group object ID (entra/groups); keys must be in var.groups"
}

variable "restrict_client_auth" {
  type        = bool
  default     = false
  description = "Use the keycloak-restrict-client-auth extension (installed by security/keycloak): realm browser flow and the Entra post-login flow deny clients with a restricted-access role to users without it"
}

variable "tofu_client_id" {
  type        = string
  default     = "opentofu"
  description = "Service account client of OpenTofu in the master realm (master.tf)"
}

variable "tofu_client_secret_version" {
  type        = number
  default     = 1
  description = "Bump to rotate the service account's secret (Keycloak + OpenBao)"
}
