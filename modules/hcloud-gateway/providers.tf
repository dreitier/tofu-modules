provider "hcloud" {
  token = ephemeral.sops_file.credentials.data["hcloud_token"]
}
