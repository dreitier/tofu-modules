# OpenBao base configuration – everything needed before Keycloak exists, so it runs with the break-glass
# login (BASEMENT_BAO_AUTH=kubernetes) on the first pass:
# - KV v2 mount for infrastructure secrets
# - kubernetes auth for the External Secrets Operator (no manual AppRole secret, unlike tg-env)
# - ACL policies
# - generated secrets: ephemeral random passwords, written write-only (never in the state); consumers
#   read them via ExternalSecrets. Rotate by bumping the entry's version.

resource "vault_mount" "kv" {
  path    = var.kv_mount
  type    = "kv"
  options = { version = "2" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

# OpenBao runs in the same cluster: it reviews tokens with its own service account
resource "vault_kubernetes_auth_backend_config" "this" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc"
}

resource "vault_kubernetes_auth_backend_role" "this" {
  for_each = var.kubernetes_roles

  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account]
  bound_service_account_namespaces = [each.value.namespace]
  token_policies                   = each.value.policies
  token_ttl                        = 3600
}

resource "vault_policy" "this" {
  for_each = var.policies

  name   = each.key
  policy = each.value
}

locals {
  generated_keys = merge([
    for path, s in var.generated_secrets : {
      for k in s.keys : "${path}/${k}" => { length = s.length }
    }
  ]...)
}

ephemeral "random_password" "this" {
  for_each = local.generated_keys

  length  = each.value.length
  special = false
}

# One KV entry per path; bumping its version regenerates every key of that entry
resource "vault_kv_secret_v2" "generated" {
  for_each = var.generated_secrets

  mount = vault_mount.kv.path
  name  = each.key

  data_json_wo         = jsonencode({ for k in each.value.keys : k => ephemeral.random_password.this["${each.key}/${k}"].result })
  data_json_wo_version = each.value.version
}
