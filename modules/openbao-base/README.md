# openbao-base

OpenBao base configuration – everything needed before Keycloak exists, so it runs with the break-glass
login (BASEMENT_BAO_AUTH=kubernetes) on the first pass:
- KV v2 mount for infrastructure secrets
- kubernetes auth for the External Secrets Operator (no manual AppRole secret, unlike tg-env)
- ACL policies
- generated secrets: ephemeral random passwords, written write-only (never in the state); consumers
```text
  read them via ExternalSecrets. Rotate by bumping the entry's version.
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_generated_secrets"></a> [generated\_secrets](#input\_generated\_secrets) | Random secrets written write-only to OpenBao; key = KV path below the mount | <pre>map(object({<br/>    keys    = set(string) # properties of the entry<br/>    length  = optional(number, 40)<br/>    version = optional(number, 1) # bump to rotate all keys of the entry<br/>  }))</pre> | `{}` | no |
| <a name="input_kubernetes_roles"></a> [kubernetes\_roles](#input\_kubernetes\_roles) | Roles of the kubernetes auth method (key = role name) | <pre>map(object({<br/>    namespace       = string<br/>    service_account = string<br/>    policies        = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | Service account token for openbao\_auth\_method = kubernetes (kubectl -n openbao create token openbao-admin) | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | OpenBao URL as seen from the workstation (via VPN) | `string` | n/a | yes |
| <a name="input_policies"></a> [policies](#input\_policies) | ACL policies (name → HCL) | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
