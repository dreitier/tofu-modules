# rancher-auth

Rancher login via Keycloak (OIDC provider "keycloakoidc"). Only members of var.access_group get in (Keycloak:
restrict-client-auth on the client; Rancher: accessMode required). var.admin_group → global admin,
var.access_group → read-only on the listed clusters. The local users (opentofu, admin) keep working.

The client secret must not reach the state, and rancher2_auth_config_keycloak_oidc keeps it as a plain
attribute. So the AuthConfig object is managed directly in Rancher's local cluster: the Secret that Rancher
would write itself (cattle-global-data/keycloakoidcconfig-clientsecret) write-only, the AuthConfig with a
reference to it – the form Rancher stores after a UI/API save.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_group"></a> [access\_group](#input\_access\_group) | Keycloak group required to log in at all (accessMode required); gets read-only on the clusters | `string` | n/a | yes |
| <a name="input_admin_group"></a> [admin\_group](#input\_admin\_group) | Keycloak group that gets Rancher's global role admin (must also be in access\_group) | `string` | n/a | yes |
| <a name="input_client_id"></a> [client\_id](#input\_client\_id) | n/a | `string` | `"rancher"` | no |
| <a name="input_client_secret_version"></a> [client\_secret\_version](#input\_client\_secret\_version) | Bump together with secret\_version of the client in config/keycloak to copy a rotated secret into Rancher | `number` | `1` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | `"dreitier"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | n/a | `string` | n/a | yes |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_oidc_kv_name"></a> [oidc\_kv\_name](#input\_oidc\_kv\_name) | OpenBao entry of the Keycloak client (client\_secret), written by config/keycloak | `string` | `"k8s/prod/oidc/rancher"` | no |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | n/a | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | Login of the vault provider (set by terragrunt-backend.hcl for every unit) | `string` | n/a | yes |
| <a name="input_rancher_token_kv_name"></a> [rancher\_token\_kv\_name](#input\_rancher\_token\_kv\_name) | OpenBao entry with key token: API key (no scope) of the Rancher local user opentofu | `string` | `"tofu/rancher"` | no |
| <a name="input_rancher_url"></a> [rancher\_url](#input\_rancher\_url) | Rancher server URL (config/globals/kubernetes.tfvars) | `string` | n/a | yes |
| <a name="input_read_only_api_groups"></a> [read\_only\_api\_groups](#input\_read\_only\_api\_groups) | API groups readable by the read-only role (all resources); the core group is listed separately without secrets | `list(string)` | n/a | yes |
| <a name="input_read_only_cluster_ids"></a> [read\_only\_cluster\_ids](#input\_read\_only\_cluster\_ids) | Cluster IDs (c-m-…) where access\_group gets the role template read\_only | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
