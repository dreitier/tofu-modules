# OpenBao speaks the Vault API → hashicorp/vault provider (login as in rancher-auth: env BASEMENT_BAO_AUTH)
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

# Rancher's local (management) cluster through the Rancher API proxy (k3s on the Rancher VM)
provider "helm" {
  kubernetes = {
    host  = "${trimsuffix(var.rancher_url, "/")}/k8s/clusters/local"
    token = ephemeral.vault_kv_secret_v2.rancher.data["token"]
  }
}
