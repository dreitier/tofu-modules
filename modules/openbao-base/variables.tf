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


variable "kv_mount" {
  type    = string
  default = "infra"
}

variable "kubernetes_roles" {
  type = map(object({
    namespace       = string
    service_account = string
    policies        = list(string)
  }))
  default     = {}
  description = "Roles of the kubernetes auth method (key = role name)"
}

variable "policies" {
  type        = map(string)
  description = "ACL policies (name → HCL)"
}

variable "generated_secrets" {
  type = map(object({
    keys    = set(string) # properties of the entry
    length  = optional(number, 40)
    version = optional(number, 1) # bump to rotate all keys of the entry
  }))
  default     = {}
  description = "Random secrets written write-only to OpenBao; key = KV path below the mount"
}
