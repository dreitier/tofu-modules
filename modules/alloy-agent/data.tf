# Rancher API key of the local service user "opentofu" (as in rancher-auth) – read ephemerally, never in the state
ephemeral "vault_kv_secret_v2" "rancher" {
  mount = var.kv_mount
  name  = var.rancher_token_kv_name
}
