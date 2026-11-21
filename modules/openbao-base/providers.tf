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
