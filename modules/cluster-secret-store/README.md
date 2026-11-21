# cluster-secret-store

ClusterSecretStore "openbao" – all ExternalSecrets in the cluster refer to it by name.
Auth: OpenBao's kubernetes auth method with the operator's own service account (config/openbao).
Changed from tg-env, where an AppRole secret ID had to be created by hand: nothing manual here.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_auth_mount"></a> [auth\_mount](#input\_auth\_mount) | n/a | `string` | `"kubernetes"` | no |
| <a name="input_auth_role"></a> [auth\_role](#input\_auth\_role) | Role of the kubernetes auth method (config/openbao) | `string` | `"external-secrets"` | no |
| <a name="input_ca_bundle_pem"></a> [ca\_bundle\_pem](#input\_ca\_bundle\_pem) | CA of the OpenBao listener if it is not publicly trusted | `string` | `null` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"openbao"` | no |
| <a name="input_openbao_server"></a> [openbao\_server](#input\_openbao\_server) | OpenBao address as seen from the cluster (in-cluster service URL) | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | n/a | <pre>object({<br/>    name      = string<br/>    namespace = string<br/>  })</pre> | <pre>{<br/>  "name": "external-secrets",<br/>  "namespace": "external-secrets"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
