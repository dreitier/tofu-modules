# keycloak-config

Keycloak configuration of the realm: OIDC clients of the apps (realm, Entra broker and NetBird clients:
realm.tf; SAML clients: saml.tf). Each client's secret is generated ephemerally and written write-only
to Keycloak and to its own OpenBao KV entry (<oidc_kv_prefix>/<key>: client_id, client_secret), where
the app's ExternalSecret reads it – it never reaches the state. The OpenBao client itself is in
config/openbao-oidc. Taken from tg-env (keycloak-config).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_clients"></a> [clients](#input\_clients) | OIDC clients (standard flow) of the apps, confidential unless public = true; key = OpenBao KV entry name | <pre>map(object({<br/>    client_id                       = optional(string) # default: map key<br/>    name                            = optional(string)<br/>    root_url                        = optional(string)<br/>    base_url                        = optional(string)<br/>    valid_redirect_uris             = list(string)<br/>    valid_post_logout_redirect_uris = optional(list(string), [])<br/>    web_origins                     = optional(list(string), [])<br/>    secret_version                  = optional(number, 1) # bump to rotate (Keycloak + OpenBao)<br/>    # Public client (PKCE S256, no secret, nothing written to OpenBao) – CLI tools such as kubelogin<br/>    public = optional(bool, false)<br/>    # Only members of these Keycloak groups may log in (client role restricted-access, needs<br/>    # restrict_client_auth); null = every user of the realm<br/>    access_groups = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_entra_client_id"></a> [entra\_client\_id](#input\_entra\_client\_id) | Client ID of the Keycloak app registration (entra/apps); null = no Entra broker | `string` | `null` | no |
| <a name="input_entra_display_name"></a> [entra\_display\_name](#input\_entra\_display\_name) | n/a | `string` | `"Microsoft Entra ID"` | no |
| <a name="input_entra_group_ids"></a> [entra\_group\_ids](#input\_entra\_group\_ids) | Keycloak group name → Entra group object ID (entra/groups); keys must be in var.groups | `map(string)` | `{}` | no |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | n/a | `string` | n/a | yes |
| <a name="input_groups"></a> [groups](#input\_groups) | Keycloak groups filled from Entra ID (mapper of the entra identity provider) | `set(string)` | `[]` | no |
| <a name="input_keycloak_admin_kv_mount"></a> [keycloak\_admin\_kv\_mount](#input\_keycloak\_admin\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_keycloak_admin_kv_name"></a> [keycloak\_admin\_kv\_name](#input\_keycloak\_admin\_kv\_name) | n/a | `string` | `"k8s/prod/keycloak"` | no |
| <a name="input_keycloak_admin_password_key"></a> [keycloak\_admin\_password\_key](#input\_keycloak\_admin\_password\_key) | n/a | `string` | `"user_admin_pass"` | no |
| <a name="input_keycloak_admin_user"></a> [keycloak\_admin\_user](#input\_keycloak\_admin\_user) | Master admin for keycloak\_auth\_method = password (bootstrap admin, or a temporary break-glass admin) | `string` | `"admin"` | no |
| <a name="input_keycloak_auth_method"></a> [keycloak\_auth\_method](#input\_keycloak\_auth\_method) | Login at Keycloak's master realm (env BASEMENT\_KEYCLOAK\_AUTH via terragrunt-backend.hcl): client\_credentials (default) – service account client "opentofu" (created by config/keycloak, secret in OpenBao infra/tofu/keycloak) password                     – a master admin user (admin-cli password grant): only the very first run of config/keycloak on a fresh Keycloak (bootstrap admin) and break-glass | `string` | `"client_credentials"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | Realm of the app clients | `string` | n/a | yes |
| <a name="input_keycloak_tofu_kv_mount"></a> [keycloak\_tofu\_kv\_mount](#input\_keycloak\_tofu\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_keycloak_tofu_kv_name"></a> [keycloak\_tofu\_kv\_name](#input\_keycloak\_tofu\_kv\_name) | OpenBao entry of the service account client (client\_id, client\_secret) | `string` | `"tofu/keycloak"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | Keycloak base URL (Keycloak >= 17: without /auth) | `string` | n/a | yes |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_netbird"></a> [netbird](#input\_netbird) | NetBird public client; null = not created | <pre>object({<br/>    dashboard_url       = string<br/>    extra_redirect_uris = optional(list(string), ["http://localhost:53000"])<br/>  })</pre> | `null` | no |
| <a name="input_oidc_kv_prefix"></a> [oidc\_kv\_prefix](#input\_oidc\_kv\_prefix) | KV path prefix of the client secrets (one entry per client, read by the apps' ExternalSecrets) | `string` | `"k8s/prod/oidc"` | no |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | Service account token for openbao\_auth\_method = kubernetes (kubectl -n openbao create token openbao-admin) | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | OpenBao URL as seen from the workstation (via VPN) | `string` | n/a | yes |
| <a name="input_realm_display_name"></a> [realm\_display\_name](#input\_realm\_display\_name) | n/a | `string` | `null` | no |
| <a name="input_restrict_client_auth"></a> [restrict\_client\_auth](#input\_restrict\_client\_auth) | Use the keycloak-restrict-client-auth extension (installed by security/keycloak): realm browser flow and the Entra post-login flow deny clients with a restricted-access role to users without it | `bool` | `false` | no |
| <a name="input_saml_clients"></a> [saml\_clients](#input\_saml\_clients) | SAML clients (service providers); key = name in this module, must not collide with var.clients | <pre>map(object({<br/>    entity_id = string # SP entity ID / issuer URL = Keycloak client_id<br/>    acs_url   = string # assertion consumer service URL (HTTP-POST), default when the request names none<br/>    # Further ACS URLs the SP may request (valid redirect URIs), e.g. AWS's IPv4/dual-stack endpoints<br/>    extra_acs_urls = optional(list(string), [])<br/>    name           = optional(string)<br/>    base_url       = optional(string) # SP start page (link in Keycloak's account console)<br/>    # username = UPN (Entra preferred_username, format unspecified), email (format emailAddress, e.g. AWS)<br/>    name_id_format            = optional(string, "username")<br/>    client_signature_required = optional(bool, false) # SP signs its AuthnRequests<br/>    # Like clients.access_groups (restricted-access role, needs restrict_client_auth)<br/>    access_groups = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tofu_client_id"></a> [tofu\_client\_id](#input\_tofu\_client\_id) | Service account client of OpenTofu in the master realm (master.tf) | `string` | `"opentofu"` | no |
| <a name="input_tofu_client_secret_version"></a> [tofu\_client\_secret\_version](#input\_tofu\_client\_secret\_version) | Bump to rotate the service account's secret (Keycloak + OpenBao) | `number` | `1` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
