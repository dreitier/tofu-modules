# Ephemeral: the credentials never reach the state (tg-env lesson: data "sops_file" persists them)
ephemeral "sops_file" "credentials" {
  source_file = var.sops_file
}
