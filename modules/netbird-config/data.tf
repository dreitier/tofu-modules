# Ephemeral: the API token never reaches the state. OpenBao infra/tofu/netbird (token) – moved from SOPS
# 2026-11-16 (config/netbird is L8, OpenBao exists by then)
ephemeral "vault_kv_secret_v2" "token" {
  mount = var.token_kv_mount
  name  = var.token_kv_name
}
