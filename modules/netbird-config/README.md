# netbird-config

NetBird account configuration through the management API (docs/netbird.md). Not in here (no provider
support or a chicken-and-egg): the Keycloak connector of the embedded IdP and the "User Approval
Required" switch (dashboard / API, runbook) – both one-time steps.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_groups"></a> [admin\_groups](#input\_admin\_groups) | JWT groups with access to the whole private network | `list(string)` | <pre>[<br/>  "infrastruktur_SG"<br/>]</pre> | no |
| <a name="input_internal_dns_ip"></a> [internal\_dns\_ip](#input\_internal\_dns\_ip) | Gateway dnsmasq (private IP) | `string` | n/a | yes |
| <a name="input_internal_domain"></a> [internal\_domain](#input\_internal\_domain) | n/a | `string` | n/a | yes |
| <a name="input_jwt_allow_groups"></a> [jwt\_allow\_groups](#input\_jwt\_allow\_groups) | Only users with one of these groups in the JWT may join; [] = no check (Keycloak restricts already). Set only after the sync is verified – a missing claim locks everyone out | `list(string)` | `[]` | no |
| <a name="input_jwt_groups_claim_name"></a> [jwt\_groups\_claim\_name](#input\_jwt\_groups\_claim\_name) | n/a | `string` | `"groups"` | no |
| <a name="input_management_url"></a> [management\_url](#input\_management\_url) | https://netbird.<domain> | `string` | n/a | yes |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | Service account token for openbao\_auth\_method = kubernetes (kubectl -n openbao create token openbao-admin) | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | OpenBao URL as seen from the workstation (via VPN) | `string` | n/a | yes |
| <a name="input_peer_login_expiration_hours"></a> [peer\_login\_expiration\_hours](#input\_peer\_login\_expiration\_hours) | n/a | `number` | `168` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Access policies from JWT groups to network resources | <pre>map(object({<br/>    sources  = list(string)     # JWT group names<br/>    resource = optional(string) # key of var.resources; null = the routing peers (gateway) themselves<br/>    protocol = string           # tcp | udp | all<br/>    ports    = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_private_network"></a> [private\_network](#input\_private\_network) | n/a | `string` | `"10.0.0.0/16"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Network resources behind the gateway (key → group res-<key>) | <pre>map(object({<br/>    address     = string<br/>    description = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_setup_key_generation"></a> [setup\_key\_generation](#input\_setup\_key\_generation) | Bump to get a new one-off setup key for the gateway | `number` | `1` | no |
| <a name="input_token_kv_mount"></a> [token\_kv\_mount](#input\_token\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_token_kv_name"></a> [token\_kv\_name](#input\_token\_kv\_name) | OpenBao entry with key `token`: personal access token of the NetBird service user opentofu | `string` | `"tofu/netbird"` | no |
| <a name="input_user_groups"></a> [user\_groups](#input\_user\_groups) | JWT groups of the employees (internal LB + DNS only) | `list(string)` | <pre>[<br/>  "vpn-access_SG"<br/>]</pre> | no |
| <a name="input_user_roles"></a> [user\_roles](#input\_user\_roles) | NetBird account roles of IdP users. A user must have logged in once (exists in NetBird). Owner is not managed here. Demote by setting "user", don't remove the entry (removing = deleting the user). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gateway_setup_key"></a> [gateway\_setup\_key](#output\_gateway\_setup\_key) | One-off setup key of the routing peer (valid 24 h): terragrunt output -raw gateway\_setup\_key |
<!-- END_TF_DOCS -->
