# OpenBao OIDC login via Keycloak, incl. its Keycloak client and the OIDC roles (bound to Keycloak
# groups, which Keycloak maps from Entra ID). Taken from tg-env's vault-config. Mounts, kubernetes auth
# and policies are in config/openbao-base (they are needed before Keycloak exists).

locals {
  oidc_discovery_url = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}"
  redirect_uris      = distinct(flatten([for r in values(var.oidc_roles) : r.allowed_redirect_uris]))
}

# --- OIDC client secret ----------------------------------------------------------------------------
# Generated per run, but only written when oidc_client_secret_version changes (write-only attributes)
# → never in the state. If an apply fails between the two writes, bump the version to resync both.
ephemeral "random_password" "oidc_client_secret" {
  length  = 48
  special = false
}

# --- Keycloak client -------------------------------------------------------------------------------

resource "keycloak_openid_client" "openbao" {
  realm_id              = var.keycloak_realm
  client_id             = var.oidc_client_id
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris   = local.redirect_uris

  client_secret_wo         = ephemeral.random_password.oidc_client_secret.result
  client_secret_wo_version = var.oidc_client_secret_version
}

# The "groups" scope (config/keycloak) is a realm client scope, not a default of new clients → assign
# it, or the ID token has no groups claim and every bound_claims check fails. The list replaces the
# client's defaults, so Keycloak's built-in ones are repeated.
resource "keycloak_openid_client_default_scopes" "openbao" {
  realm_id       = var.keycloak_realm
  client_id      = keycloak_openid_client.openbao.id
  default_scopes = ["basic", "acr", "profile", "email", "roles", "web-origins", "groups"]
}

# --- Vault OIDC auth -------------------------------------------------------------------------------

resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = local.oidc_discovery_url
  oidc_client_id     = keycloak_openid_client.openbao.client_id
  default_role       = var.oidc_default_role
  namespace_in_state = true

  oidc_client_secret_wo         = ephemeral.random_password.oidc_client_secret.result
  oidc_client_secret_wo_version = var.oidc_client_secret_version
}

resource "vault_jwt_auth_backend_role" "oidc" {
  for_each = var.oidc_roles

  backend               = vault_jwt_auth_backend.oidc.path
  role_name             = each.key
  role_type             = "oidc"
  user_claim            = "sub"
  bound_claims_type     = "string"
  bound_claims          = { groups = join(",", each.value.bound_groups) }
  allowed_redirect_uris = each.value.allowed_redirect_uris
  token_policies        = each.value.token_policies
  token_ttl             = each.value.token_ttl
}
