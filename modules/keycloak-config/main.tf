# Keycloak configuration of the realm: OIDC clients of the apps (realm, Entra broker and NetBird clients:
# realm.tf; SAML clients: saml.tf). Each client's secret is generated ephemerally and written write-only
# to Keycloak and to its own OpenBao KV entry (<oidc_kv_prefix>/<key>: client_id, client_secret), where
# the app's ExternalSecret reads it – it never reaches the state. The OpenBao client itself is in
# config/openbao-oidc. Taken from tg-env (keycloak-config).

# Generated per run, but only written when the client's secret_version changes. If an apply fails
# between the two writes, bump secret_version to resync both.
locals {
  confidential_clients = { for k, c in var.clients : k => c if !c.public }
}

ephemeral "random_password" "client_secret" {
  for_each = local.confidential_clients

  length  = 48
  special = false
}

resource "keycloak_openid_client" "this" {
  for_each = var.clients

  realm_id    = keycloak_realm.this.id
  client_id   = coalesce(each.value.client_id, each.key)
  name        = each.value.name
  enabled     = true
  access_type = each.value.public ? "PUBLIC" : "CONFIDENTIAL"

  standard_flow_enabled           = true
  direct_access_grants_enabled    = false
  root_url                        = each.value.root_url
  base_url                        = each.value.base_url
  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  web_origins                     = each.value.web_origins

  pkce_code_challenge_method = each.value.public ? "S256" : null

  client_secret_wo         = each.value.public ? null : ephemeral.random_password.client_secret[each.key].result
  client_secret_wo_version = each.value.public ? null : each.value.secret_version
}

resource "vault_kv_secret_v2" "client" {
  for_each = local.confidential_clients

  mount = var.kv_mount
  name  = "${var.oidc_kv_prefix}/${each.key}"

  data_json_wo = jsonencode({
    client_id     = keycloak_openid_client.this[each.key].client_id
    client_secret = ephemeral.random_password.client_secret[each.key].result
  })
  data_json_wo_version = each.value.secret_version
}

# Groups claim for the apps: the "groups" scope (realm.tf) is not a default of new clients. The list
# replaces the client's defaults, so Keycloak's built-in ones are repeated.
resource "keycloak_openid_client_default_scopes" "this" {
  for_each = var.clients

  realm_id       = keycloak_realm.this.id
  client_id      = keycloak_openid_client.this[each.key].id
  default_scopes = local.client_default_scopes
}
