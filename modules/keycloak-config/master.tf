# Master realm: service account client "opentofu" – Tofu's login at Keycloak (config/keycloak, config/openbao-oidc)
# instead of the bootstrap admin. Realm role "admin" of the master realm = full admin of every realm. Its secret
# is generated ephemerally and written write-only to Keycloak and to OpenBao infra/tofu/keycloak (never in
# state). Created by the first run of this unit with BASEMENT_KEYCLOAK_AUTH=password (bootstrap admin).
# Rotation: bump var.tofu_client_secret_version – both writes happen in the same run (the provider is already
# logged in with the old secret). If one write fails, the service account is locked out → break-glass
# (docs/handbook/runbooks/break-glass.md, kc.sh bootstrap-admin service) and apply again.

ephemeral "random_password" "tofu_client_secret" {
  length  = 48
  special = false
}

resource "keycloak_openid_client" "tofu" {
  realm_id    = "master"
  client_id   = var.tofu_client_id
  name        = "OpenTofu (basement)"
  description = "Service account of OpenTofu (dreitier/basement) – secret in OpenBao infra/${var.keycloak_tofu_kv_name}"
  enabled     = true
  access_type = "CONFIDENTIAL"

  service_accounts_enabled     = true
  standard_flow_enabled        = false
  direct_access_grants_enabled = false

  client_secret_wo         = ephemeral.random_password.tofu_client_secret.result
  client_secret_wo_version = var.tofu_client_secret_version
}

# Keycloak >= 26.8.2 only accepts Admin REST API tokens that carry the scope kc-admin-api (audience = the
# realm's admin API URL) – without it every call is 401 although the roles are there. Upgrades assign it to
# admin-cli/security-admin-console only. The list replaces the client's defaults: Keycloak's built-ins +
# service_account (claims of service account tokens) + kc-admin-api.
resource "keycloak_openid_client_default_scopes" "tofu" {
  realm_id       = "master"
  client_id      = keycloak_openid_client.tofu.id
  default_scopes = ["acr", "basic", "email", "profile", "roles", "service_account", "web-origins", "kc-admin-api"]
}

resource "keycloak_openid_client_service_account_realm_role" "tofu_admin" {
  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.tofu.service_account_user_id
  role                    = "admin"
}

resource "vault_kv_secret_v2" "tofu_client" {
  mount = var.keycloak_tofu_kv_mount
  name  = var.keycloak_tofu_kv_name

  data_json_wo = jsonencode({
    client_id     = keycloak_openid_client.tofu.client_id
    client_secret = ephemeral.random_password.tofu_client_secret.result
  })
  data_json_wo_version = var.tofu_client_secret_version
}
