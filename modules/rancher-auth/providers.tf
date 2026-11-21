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

# Rancher API key of the local service user "opentofu" (OpenBao infra/tofu/rancher, read ephemerally) –
# unlike rke2-managed no login per run, so no token ends up in the state
provider "rancher2" {
  api_url   = var.rancher_url
  token_key = ephemeral.vault_kv_secret_v2.rancher.data["token"]
}

# Rancher's local (management) cluster through the Rancher API proxy: the client secret (kubernetes) and the
# AuthConfig (kubectl, server-side apply)
provider "kubernetes" {
  host  = "${trimsuffix(var.rancher_url, "/")}/k8s/clusters/local"
  token = ephemeral.vault_kv_secret_v2.rancher.data["token"]
}

provider "kubectl" {
  host             = "${trimsuffix(var.rancher_url, "/")}/k8s/clusters/local"
  token            = ephemeral.vault_kv_secret_v2.rancher.data["token"]
  load_config_file = false
}
