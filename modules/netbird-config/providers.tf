# OpenBao speaks the Vault API → hashicorp/vault provider (login as in keycloak-config: env BASEMENT_BAO_AUTH)
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

# Personal access token of a NetBird service user (dashboard: Users → Service Users, role admin), OpenBao
provider "netbird" {
  management_url = var.management_url
  token          = ephemeral.vault_kv_secret_v2.token.data["token"]
}
