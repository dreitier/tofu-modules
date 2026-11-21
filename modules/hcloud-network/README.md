# hcloud-network

Private network of the cluster. Nodes have no public IP: every packet leaves through the gateway
(NAT) – a default route in the network points to it. The VPN client ranges route back to it, too.
Hetzner Cloud Firewalls only filter public interfaces – inside this network NetworkPolicies and
host firewalls do the filtering.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_gateway_ip"></a> [gateway\_ip](#input\_gateway\_ip) | Fixed private IP of the gateway server (not .1 – that is Hetzner's router) | `string` | n/a | yes |
| <a name="input_ip_range"></a> [ip\_range](#input\_ip\_range) | n/a | `string` | `"10.0.0.0/16"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_network_zone"></a> [network\_zone](#input\_network\_zone) | n/a | `string` | `"eu-central"` | no |
| <a name="input_placement_groups"></a> [placement\_groups](#input\_placement\_groups) | n/a | `list(string)` | <pre>[<br/>  "controlplane",<br/>  "worker"<br/>]</pre> | no |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Admin SSH public keys by name (created as hcloud\_ssh\_key, IDs go to all servers) | `map(string)` | `{}` | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | n/a | `string` | `"10.0.1.0/24"` | no |
| <a name="input_vpn_ranges"></a> [vpn\_ranges](#input\_vpn\_ranges) | Client ranges of the VPNs, routed back via the gateway | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gateway_ip"></a> [gateway\_ip](#output\_gateway\_ip) | Private IP of the gateway server (route target) |
| <a name="output_ip_range"></a> [ip\_range](#output\_ip\_range) | n/a |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | n/a |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | n/a |
| <a name="output_network_router_ip"></a> [network\_router\_ip](#output\_network\_router\_ip) | Hetzner's router in the network – next hop of the servers' default route |
| <a name="output_placement_group_ids"></a> [placement\_group\_ids](#output\_placement\_group\_ids) | n/a |
| <a name="output_ssh_key_ids"></a> [ssh\_key\_ids](#output\_ssh\_key\_ids) | IDs of the admin SSH keys |
<!-- END_TF_DOCS -->
