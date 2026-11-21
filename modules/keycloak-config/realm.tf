# Realm, identity brokering to Entra ID and the NetBird clients.
# Entra ID stays the single source of truth for identities: users log in at Entra through Keycloak's
# identity provider; Keycloak only maps Entra groups to its own groups (= claims for OpenBao, NetBird,
# apps). No local users besides the master admin.

resource "keycloak_realm" "this" {
  realm        = var.keycloak_realm
  enabled      = true
  display_name = var.realm_display_name

  # Users only come from Entra → no registration, no local password reset
  registration_allowed     = false
  reset_password_allowed   = false
  login_with_email_allowed = true

  lifecycle {
    prevent_destroy = true
  }
}

# Entra broker: Keycloak authenticates with private_key_jwt – the client assertion is signed with the
# realm's RS256 key, whose certificate entra/apps registers on the app (2nd pass). No client secret
# anywhere; the provider insists on one, so a dummy goes write-only (never in state, unused by Keycloak).
locals {
  entra_base = "https://login.microsoftonline.com/${var.entra_tenant_id}"
}

resource "keycloak_oidc_identity_provider" "entra" {
  count = var.entra_client_id == null ? 0 : 1

  realm        = keycloak_realm.this.id
  alias        = "entra"
  display_name = var.entra_display_name

  authorization_url  = "${local.entra_base}/oauth2/v2.0/authorize"
  token_url          = "${local.entra_base}/oauth2/v2.0/token"
  logout_url         = "${local.entra_base}/oauth2/v2.0/logout"
  issuer             = "${local.entra_base}/v2.0"
  jwks_url           = "${local.entra_base}/discovery/v2.0/keys"
  validate_signature = true
  disable_user_info  = true # Entra's userinfo is Graph – everything needed is in the ID token

  client_id                = var.entra_client_id
  client_secret_wo         = "unused-private-key-jwt"
  client_secret_wo_version = 1

  default_scopes = "openid profile email"

  # Per-client access check after the Entra login (access.tf)
  post_broker_login_flow_alias = one(keycloak_authentication_flow.post_broker[*].alias)
  sync_mode                    = "FORCE"
  trust_email                  = true
  store_token                  = false

  extra_config = {
    clientAuthMethod          = "private_key_jwt"
    clientAssertionSigningAlg = "RS256"
    # Entra identifies the signing certificate by its thumbprint (x5t header)
    jwtX509HeadersEnabled = "true"
  }
}

# Username = UPN (stable, readable); Entra's sub is pairwise per app
resource "keycloak_custom_identity_provider_mapper" "entra_username" {
  count = length(keycloak_oidc_identity_provider.entra)

  realm                    = keycloak_realm.this.id
  identity_provider_alias  = keycloak_oidc_identity_provider.entra[0].alias
  name                     = "username"
  identity_provider_mapper = "oidc-username-idp-mapper"
  extra_config = {
    syncMode = "FORCE"
    template = "$${CLAIM.preferred_username}"
  }
}

# Entra group (object ID in the groups claim) → Keycloak group of the same name
resource "keycloak_custom_identity_provider_mapper" "entra_groups" {
  for_each = length(keycloak_oidc_identity_provider.entra) == 0 ? {} : var.entra_group_ids

  realm                    = keycloak_realm.this.id
  identity_provider_alias  = keycloak_oidc_identity_provider.entra[0].alias
  name                     = "group ${each.key}"
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"
  extra_config = {
    syncMode                 = "FORCE"
    claims                   = jsonencode([{ key = "groups", value = each.value }])
    "are.claim.values.regex" = "false"
    group                    = "/${keycloak_group.this[each.key].name}"
  }
}

# Keycloak groups that the Entra mapper fills; referenced by OpenBao OIDC roles and NetBird
resource "keycloak_group" "this" {
  for_each = var.groups

  realm_id = keycloak_realm.this.id
  name     = each.key
}

locals {
  # Default scopes of every client of this realm: Keycloak's built-ins + groups
  client_default_scopes = ["basic", "acr", "profile", "email", "roles", "web-origins", keycloak_openid_client_scope.groups.name]
}

# Group membership as "groups" claim in tokens (OpenBao bound_claims, NetBird JWT group sync)
resource "keycloak_openid_client_scope" "groups" {
  realm_id               = keycloak_realm.this.id
  name                   = "groups"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id        = keycloak_realm.this.id
  client_scope_id = keycloak_openid_client_scope.groups.id
  name            = "groups"
  claim_name      = "groups"
  full_path       = false
}

# --- NetBird ------------------------------------------------------------------------------------------
# netbird-client: public client of the dashboard and the NetBird apps (PKCE, device flow for headless
# peers). Its secret-less nature is intended. The backend client for NetBird's IdP manager (service
# account with view-users/query-users on realm-management) is a confidential client in var.clients
# style; its secret goes write-only to Keycloak and OpenBao like the app clients.

resource "keycloak_openid_client" "netbird" {
  count = var.netbird == null ? 0 : 1

  realm_id    = keycloak_realm.this.id
  client_id   = "netbird-client"
  name        = "NetBird"
  enabled     = true
  access_type = "PUBLIC"

  standard_flow_enabled                     = true
  oauth2_device_authorization_grant_enabled = true
  direct_access_grants_enabled              = false

  root_url            = var.netbird.dashboard_url
  valid_redirect_uris = concat(["${var.netbird.dashboard_url}/*"], var.netbird.extra_redirect_uris)
  web_origins         = [var.netbird.dashboard_url]

  pkce_code_challenge_method = "S256"
}

resource "keycloak_openid_client_default_scopes" "netbird" {
  count = length(keycloak_openid_client.netbird)

  realm_id       = keycloak_realm.this.id
  client_id      = keycloak_openid_client.netbird[0].id
  default_scopes = local.client_default_scopes
}

# TODO netbird-backend (confidential, service_accounts_enabled = true) + keycloak_openid_client_service_account_role
# for realm-management view-users and query-users; secret like the app clients (ephemeral → client_secret_wo
# + data_json_wo in OpenBao <oidc_kv_prefix>/netbird-backend)
