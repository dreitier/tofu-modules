# entra-apps

Enterprise applications / app registrations of the consumers of Entra ID. First one: Keycloak as
identity broker. TODO AWS IAM Identity Center (SAML + SCIM), GitHub (SAML, needs Enterprise Cloud).

Keycloak broker: OIDC web app with redirect URI https://<idp>/realms/<realm>/broker/entra/endpoint,
groups claim (security groups) in ID tokens. Credential: a certificate (public key only, uploaded here)
instead of a client secret – azuread_application_password would put the secret into the state.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | n/a | `string` | n/a | yes |
| <a name="input_imported_apps"></a> [imported\_apps](#input\_imported\_apps) | Existing applications (imported, configuration ignored) and their app role assignments | <pre>map(object({<br/>    display_name                = string<br/>    application_object_id       = string<br/>    service_principal_object_id = string<br/>    assignments = optional(list(object({<br/>      principal_type = string           # Group | User<br/>      principal      = string           # group display name | user principal name<br/>      app_role_id    = optional(string) # null = default access (app without app roles)<br/>      import_id      = optional(string) # ID of the existing assignment → import<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_keycloak_app_name"></a> [keycloak\_app\_name](#input\_keycloak\_app\_name) | n/a | `string` | `"Keycloak"` | no |
| <a name="input_keycloak_broker_certificate_end_date"></a> [keycloak\_broker\_certificate\_end\_date](#input\_keycloak\_broker\_certificate\_end\_date) | n/a | `string` | `null` | no |
| <a name="input_keycloak_broker_certificate_pem"></a> [keycloak\_broker\_certificate\_pem](#input\_keycloak\_broker\_certificate\_pem) | Public certificate of Keycloak's client assertion key (private key stays in Keycloak) | `string` | `null` | no |
| <a name="input_keycloak_broker_redirect_uri"></a> [keycloak\_broker\_redirect\_uri](#input\_keycloak\_broker\_redirect\_uri) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_enabled"></a> [keycloak\_enabled](#input\_keycloak\_enabled) | Create the app registration of the new Keycloak (switch on together with security/keycloak) | `bool` | `true` | no |
| <a name="input_keycloak_realm_jwks_url"></a> [keycloak\_realm\_jwks\_url](#input\_keycloak\_realm\_jwks\_url) | JWKS URL of the Keycloak realm – the certificate of its RS256 signing key becomes the app credential | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_imported_client_ids"></a> [imported\_client\_ids](#output\_imported\_client\_ids) | n/a |
| <a name="output_keycloak_certificate_installed"></a> [keycloak\_certificate\_installed](#output\_keycloak\_certificate\_installed) | Whether the Keycloak realm certificate is registered (private\_key\_jwt works) |
| <a name="output_keycloak_client_id"></a> [keycloak\_client\_id](#output\_keycloak\_client\_id) | n/a |
<!-- END_TF_DOCS -->
