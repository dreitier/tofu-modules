# Dedicated INWX API sub-account, limited to the DNS of this domain if possible. With 2FA the provider
# computes the TAN itself from the TOTP shared secret (inwx_shared_secret in SOPS, Base32; optional).
provider "inwx" {
  username      = ephemeral.sops_file.credentials.data["inwx_username"]
  password      = ephemeral.sops_file.credentials.data["inwx_password"]
  shared_secret = try(coalesce(ephemeral.sops_file.credentials.data["inwx_shared_secret"]), null) # missing or "" = no 2FA
}
