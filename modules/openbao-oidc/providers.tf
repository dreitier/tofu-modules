# OpenBao speaks the Vault API → hashicorp/vault provider. Login method from terragrunt-backend.hcl
# (env BASEMENT_BAO_AUTH): oidc = browser login via Keycloak (callback http://localhost:8250/oidc/callback),
# kubernetes = token of the service account openbao/openbao-admin, self-init admin role on the mount
# kubernetes-admin (first runs before Keycloak exists, break-glass). No root token anywhere.
provider "vault" {
  address          = var.openbao_url
  skip_child_token = true

  dynamic "auth_login_oidc" {
    for_each = var.openbao_auth_method == "oidc" ? [1] : []
    content {
      mount = "oidc"
      role  = var.openbao_oidc_role
    }
  }

  dynamic "auth_login" {
    for_each = var.openbao_auth_method == "kubernetes" ? [1] : []
    content {
      path       = "auth/kubernetes-admin/login"
      parameters = { role = "admin", jwt = var.openbao_jwt }
    }
  }
}

# Keycloak master realm: service account client "opentofu" (client credentials) or, for bootstrap/break-glass,
# a master admin user (password grant via admin-cli). Secrets from OpenBao, read ephemerally.
provider "keycloak" {
  url           = var.keycloak_url
  realm         = "master"
  client_id     = var.keycloak_auth_method == "password" ? "admin-cli" : try(ephemeral.vault_kv_secret_v2.keycloak_tofu[0].data["client_id"], null)
  client_secret = var.keycloak_auth_method == "password" ? null : try(ephemeral.vault_kv_secret_v2.keycloak_tofu[0].data["client_secret"], null)
  username      = var.keycloak_auth_method == "password" ? var.keycloak_admin_user : null
  password      = var.keycloak_auth_method == "password" ? try(ephemeral.vault_kv_secret_v2.keycloak_admin[0].data[var.keycloak_admin_password_key], null) : null
}
