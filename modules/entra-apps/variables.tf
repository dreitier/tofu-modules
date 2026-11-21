variable "entra_tenant_id" {
  type = string
}

variable "keycloak_enabled" {
  type        = bool
  default     = true
  description = "Create the app registration of the new Keycloak (switch on together with security/keycloak)"
}

variable "keycloak_app_name" {
  type    = string
  default = "Keycloak"
}

variable "keycloak_broker_redirect_uri" {
  type = string
}

variable "keycloak_broker_certificate_pem" {
  type        = string
  default     = null
  description = "Public certificate of Keycloak's client assertion key (private key stays in Keycloak)"
}

variable "keycloak_realm_jwks_url" {
  type        = string
  default     = null
  description = "JWKS URL of the Keycloak realm – the certificate of its RS256 signing key becomes the app credential"
}

variable "keycloak_broker_certificate_end_date" {
  type    = string
  default = null
}

variable "imported_apps" {
  type = map(object({
    display_name                = string
    application_object_id       = string
    service_principal_object_id = string
    assignments = optional(list(object({
      principal_type = string           # Group | User
      principal      = string           # group display name | user principal name
      app_role_id    = optional(string) # null = default access (app without app roles)
      import_id      = optional(string) # ID of the existing assignment → import
    })), [])
  }))
  default     = {}
  description = "Existing applications (imported, configuration ignored) and their app role assignments"
}
