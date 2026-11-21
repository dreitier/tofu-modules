output "keycloak_certificate_installed" {
  value       = length(azuread_application_certificate.keycloak) > 0
  description = "Whether the Keycloak realm certificate is registered (private_key_jwt works)"
}

output "keycloak_client_id" {
  value = one(azuread_application.keycloak[*].client_id)
}

output "imported_client_ids" {
  value = { for k, a in azuread_application.imported : k => a.client_id }
}
