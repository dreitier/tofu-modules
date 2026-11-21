# Preferred: a GitHub App owned by the organization (installation on all repositories; permissions:
# organization Administration + Members RW, repository Administration RW, Metadata R). Its private key is
# in SOPS (github_admin_app_private_key). Fallback: a token (github_token), e.g. for the very first run.
provider "github" {
  owner = var.github_owner
  token = var.github_admin_app == null ? ephemeral.sops_file.credentials.data["github_token"] : null

  dynamic "app_auth" {
    for_each = var.github_admin_app == null ? [] : [var.github_admin_app]
    content {
      id              = app_auth.value.app_id
      installation_id = app_auth.value.installation_id
      pem_file        = ephemeral.sops_file.credentials.data["github_admin_app_private_key"]
    }
  }
}
