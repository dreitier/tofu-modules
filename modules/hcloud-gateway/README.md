# hcloud-gateway

Gateway: the only server with a public IP besides the load balancers.
- NAT for the private network (egress of all nodes: image pulls, Rancher agent, STS/KMS)
- plain WireGuard as bootstrap/break-glass access (works before the cluster and NetBird exist)
- later NetBird routing peer for the private network (apps/netbird)
- DNS for VPN clients and the servers of the private network (dnsmasq on wg0 + private IP): the internal zone resolves to private IPs and never appears in
```text
  public DNS; everything else is forwarded. The internal names are static (wildcard → internal load
  balancer with a fixed private IP, plus single hosts), so they can live in the one-shot cloud-init.
```
The WireGuard key is generated on the host at first boot – no private key in cloud-init, SOPS or state.
Single point of failure for egress and VPN: rebuildable from this unit; keep its snapshot policy in mind.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_image"></a> [image](#input\_image) | n/a | `string` | `"debian-13"` | no |
| <a name="input_internal_dns_records"></a> [internal\_dns\_records](#input\_internal\_dns\_records) | dnsmasq address records for VPN clients: domain → IPv4. A domain covers all its subdomains (address=/<domain>/<ip>), the most specific entry wins. | `map(string)` | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"gateway"` | no |
| <a name="input_netbird_wireguard_port"></a> [netbird\_wireguard\_port](#input\_netbird\_wireguard\_port) | UDP port of the NetBird client on the gateway (routing peer) – not the break-glass WireGuard port | `number` | `51821` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | n/a | `string` | n/a | yes |
| <a name="input_network_range"></a> [network\_range](#input\_network\_range) | n/a | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Fixed private IP – the target of the network's default route | `string` | n/a | yes |
| <a name="input_server_type"></a> [server\_type](#input\_server\_type) | n/a | `string` | `"cpx22"` | no |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | hcloud SSH key names/IDs for the initial login | `list(string)` | `[]` | no |
| <a name="input_ssh_source_ips"></a> [ssh\_source\_ips](#input\_ssh\_source\_ips) | Admin networks allowed to SSH to the gateway | `list(string)` | n/a | yes |
| <a name="input_wireguard_port"></a> [wireguard\_port](#input\_wireguard\_port) | n/a | `number` | `51820` | no |
| <a name="input_wireguard_range"></a> [wireguard\_range](#input\_wireguard\_range) | n/a | `string` | `"10.99.0.0/24"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | n/a |
| <a name="output_public_ipv4"></a> [public\_ipv4](#output\_public\_ipv4) | n/a |
<!-- END_TF_DOCS -->
