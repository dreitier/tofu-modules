# Rancher API key of the local user "opentofu" (key "token" = "token-xxxxx:secret")
ephemeral "vault_kv_secret_v2" "rancher" {
  mount = var.kv_mount
  name  = var.rancher_token_kv_name
}

# Secret of the Keycloak client (written by config/keycloak)
ephemeral "vault_kv_secret_v2" "oidc" {
  mount = var.kv_mount
  name  = var.oidc_kv_name
}
