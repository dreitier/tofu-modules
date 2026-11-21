# Ephemeral: the App key / token never reaches the state
ephemeral "sops_file" "credentials" {
  source_file = var.sops_file
}
