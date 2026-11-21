# Per-client access restriction (keycloak-restrict-client-auth, installed by security/keycloak).
# Keycloak can't deny a brokered login per client by itself: the browser flow ends with the broker
# redirect. The extension's authenticator therefore runs in two places – after the login part of the
# realm's browser flow (cookie logins) and in the post-login flow of the Entra broker (fresh logins).
# A client is restricted once it has the client role "restricted-access"; only users holding it (here:
# via clients.<x>.access_groups) get in. Clients without that role stay open to the whole realm.

locals {
  # OIDC and SAML clients share the keys of this map (saml_clients must not reuse a key of clients)
  restricted_clients = merge(
    { for k, c in var.clients : k => c.access_groups if c.access_groups != null },
    { for k, c in var.saml_clients : k => c.access_groups if c.access_groups != null },
  )
  restricted_client_ids = merge(
    { for k, c in keycloak_openid_client.this : k => c.id },
    { for k, c in keycloak_saml_client.this : k => c.id },
  )
  access_group_pairs = merge([
    for k, groups in local.restricted_clients : { for g in groups : "${k}/${g}" => { client = k, group = g } }
  ]...)
}

resource "keycloak_role" "restricted_access" {
  for_each = local.restricted_clients

  realm_id    = keycloak_realm.this.id
  client_id   = local.restricted_client_ids[each.key]
  name        = "restricted-access"
  description = "Login allowed (keycloak-restrict-client-auth)"
}

resource "keycloak_group_roles" "restricted_access" {
  for_each = local.access_group_pairs

  realm_id   = keycloak_realm.this.id
  group_id   = keycloak_group.this[each.value.group].id
  role_ids   = [keycloak_role.restricted_access[each.value.client].id]
  exhaustive = false
}

# --- Browser flow: login (cookie or straight to Entra), then the access check ---------------------

resource "keycloak_authentication_flow" "browser" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id    = keycloak_realm.this.id
  alias       = "browser-entra"
  description = "Cookie or Entra ID, then the per-client access check"
}

resource "keycloak_authentication_subflow" "browser_login" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id          = keycloak_realm.this.id
  parent_flow_alias = keycloak_authentication_flow.browser[0].alias
  alias             = "browser-entra login"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "browser_cookie" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id          = keycloak_realm.this.id
  parent_flow_alias = keycloak_authentication_subflow.browser_login[0].alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "browser_idp" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id          = keycloak_realm.this.id
  parent_flow_alias = keycloak_authentication_subflow.browser_login[0].alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"

  depends_on = [keycloak_authentication_execution.browser_cookie]
}

# Straight to Entra – there are no local users in this realm
resource "keycloak_authentication_execution_config" "browser_idp" {
  count = var.restrict_client_auth && length(keycloak_oidc_identity_provider.entra) > 0 ? 1 : 0

  realm_id     = keycloak_realm.this.id
  execution_id = keycloak_authentication_execution.browser_idp[0].id
  alias        = "entra-default"
  config       = { defaultProvider = keycloak_oidc_identity_provider.entra[0].alias }
}

resource "keycloak_authentication_execution" "browser_restrict" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id          = keycloak_realm.this.id
  parent_flow_alias = keycloak_authentication_flow.browser[0].alias
  authenticator     = "restrict-client-auth-authenticator"
  requirement       = "REQUIRED"

  depends_on = [keycloak_authentication_subflow.browser_login, keycloak_authentication_execution.browser_idp]
}

resource "keycloak_authentication_bindings" "this" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id     = keycloak_realm.this.id
  browser_flow = keycloak_authentication_flow.browser[0].alias

  depends_on = [keycloak_authentication_execution.browser_restrict, keycloak_authentication_execution_config.browser_idp]
}

# --- Post-login flow of the Entra broker ----------------------------------------------------------

resource "keycloak_authentication_flow" "post_broker" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id    = keycloak_realm.this.id
  alias       = "post-broker-restrict"
  description = "Per-client access check after every Entra login"
}

resource "keycloak_authentication_execution" "post_broker_restrict" {
  count = var.restrict_client_auth ? 1 : 0

  realm_id          = keycloak_realm.this.id
  parent_flow_alias = keycloak_authentication_flow.post_broker[0].alias
  authenticator     = "restrict-client-auth-authenticator"
  requirement       = "REQUIRED"
}
