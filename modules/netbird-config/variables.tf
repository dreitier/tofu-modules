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

variable "token_kv_mount" {
  type    = string
  default = "infra"
}

variable "token_kv_name" {
  type        = string
  default     = "tofu/netbird"
  description = "OpenBao entry with key `token`: personal access token of the NetBird service user opentofu"
}

variable "management_url" {
  type        = string
  description = "https://netbird.<domain>"
}

variable "jwt_groups_claim_name" {
  type    = string
  default = "groups"
}

variable "jwt_allow_groups" {
  type        = list(string)
  default     = []
  description = "Only users with one of these groups in the JWT may join; [] = no check (Keycloak restricts already). Set only after the sync is verified – a missing claim locks everyone out"
}

variable "peer_login_expiration_hours" {
  type    = number
  default = 168
}

variable "user_groups" {
  type        = list(string)
  default     = ["vpn-access_SG"]
  description = "JWT groups of the employees (internal LB + DNS only)"
}

variable "admin_groups" {
  type        = list(string)
  default     = ["infrastruktur_SG"]
  description = "JWT groups with access to the whole private network"
}

variable "private_network" {
  type    = string
  default = "10.0.0.0/16"
}

variable "internal_domain" {
  type = string
}

variable "internal_dns_ip" {
  type        = string
  description = "Gateway dnsmasq (private IP)"
}

variable "resources" {
  type = map(object({
    address     = string
    description = optional(string)
  }))
  description = "Network resources behind the gateway (key → group res-<key>)"
}

variable "policies" {
  type = map(object({
    sources  = list(string)     # JWT group names
    resource = optional(string) # key of var.resources; null = the routing peers (gateway) themselves
    protocol = string           # tcp | udp | all
    ports    = optional(list(string))
  }))
  description = "Access policies from JWT groups to network resources"
}

variable "setup_key_generation" {
  type        = number
  default     = 1
  description = "Bump to get a new one-off setup key for the gateway"
}

variable "user_roles" {
  type        = map(string) # E-Mail → admin | user | auditor | network_admin
  default     = {}
  description = "NetBird account roles of IdP users. A user must have logged in once (exists in NetBird). Owner is not managed here. Demote by setting \"user\", don't remove the entry (removing = deleting the user)."

  validation {
    condition     = alltrue([for r in values(var.user_roles) : contains(["admin", "user", "auditor", "network_admin"], r)])
    error_message = "owner is set by hand (transfer ownership), not here."
  }
}
