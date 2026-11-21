# openbao-oidc

OpenBao OIDC login via Keycloak, incl. its Keycloak client and the OIDC roles (bound to Keycloak
groups, which Keycloak maps from Entra ID). Taken from tg-env's vault-config. Mounts, kubernetes auth
and policies are in config/openbao-base (they are needed before Keycloak exists).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_keycloak_admin_kv_mount"></a> [keycloak\_admin\_kv\_mount](#input\_keycloak\_admin\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_keycloak_admin_kv_name"></a> [keycloak\_admin\_kv\_name](#input\_keycloak\_admin\_kv\_name) | n/a | `string` | `"k8s/prod/keycloak"` | no |
| <a name="input_keycloak_admin_password_key"></a> [keycloak\_admin\_password\_key](#input\_keycloak\_admin\_password\_key) | n/a | `string` | `"user_admin_pass"` | no |
| <a name="input_keycloak_admin_user"></a> [keycloak\_admin\_user](#input\_keycloak\_admin\_user) | Master admin for keycloak\_auth\_method = password (bootstrap admin, or a temporary break-glass admin) | `string` | `"admin"` | no |
| <a name="input_keycloak_auth_method"></a> [keycloak\_auth\_method](#input\_keycloak\_auth\_method) | Login at Keycloak's master realm (env BASEMENT\_KEYCLOAK\_AUTH via terragrunt-backend.hcl): client\_credentials (default) – service account client "opentofu" (created by config/keycloak, secret in OpenBao infra/tofu/keycloak) password                     – a master admin user (admin-cli password grant): only the very first run of config/keycloak on a fresh Keycloak (bootstrap admin) and break-glass | `string` | `"client_credentials"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | Realm that holds the OpenBao client | `string` | n/a | yes |
| <a name="input_keycloak_tofu_kv_mount"></a> [keycloak\_tofu\_kv\_mount](#input\_keycloak\_tofu\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_keycloak_tofu_kv_name"></a> [keycloak\_tofu\_kv\_name](#input\_keycloak\_tofu\_kv\_name) | OpenBao entry of the service account client (client\_id, client\_secret) | `string` | `"tofu/keycloak"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | Keycloak base URL (Keycloak >= 17: without /auth) | `string` | n/a | yes |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | `"openbao"` | no |
| <a name="input_oidc_client_secret_version"></a> [oidc\_client\_secret\_version](#input\_oidc\_client\_secret\_version) | Bump to rotate the OIDC client secret (written write-only to Keycloak and OpenBao) | `number` | `1` | no |
| <a name="input_oidc_default_role"></a> [oidc\_default\_role](#input\_oidc\_default\_role) | n/a | `string` | n/a | yes |
| <a name="input_oidc_roles"></a> [oidc\_roles](#input\_oidc\_roles) | OIDC roles (key = role name); bound to the Keycloak groups claim | <pre>map(object({<br/>    bound_groups          = list(string)<br/>    token_policies        = list(string)<br/>    token_ttl             = optional(number, 3600)<br/>    allowed_redirect_uris = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | Service account token for openbao\_auth\_method = kubernetes (kubectl -n openbao create token openbao-admin) | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | OpenBao URL as seen from the workstation (via VPN) | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
