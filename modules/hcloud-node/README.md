# hcloud-node

One RKE2 node of a Rancher custom cluster: private network only, registered once via cloud-init with
the node command of the cluster unit plus its roles. One unit per node (stages/…/nodes/<name>), shared
settings in nodes/node.hcl – same layout as tg-env's VMs.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_base_runcmd"></a> [base\_runcmd](#input\_base\_runcmd) | n/a | `list(string)` | `[]` | no |
| <a name="input_gateway_ip"></a> [gateway\_ip](#input\_gateway\_ip) | Private IP of the gateway: DNS resolver (dnsmasq) of the server (config/globals/hetzner.tfvars) | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | n/a | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | n/a | `string` | n/a | yes |
| <a name="input_network_router_ip"></a> [network\_router\_ip](#input\_network\_router\_ip) | Hetzner's router in the network (first IP of the network range) | `string` | n/a | yes |
| <a name="input_node_command"></a> [node\_command](#input\_node\_command) | Registration command of the cluster unit (output node\_command) | `string` | n/a | yes |
| <a name="input_packages"></a> [packages](#input\_packages) | n/a | `list(string)` | `[]` | no |
| <a name="input_placement_group_id"></a> [placement\_group\_id](#input\_placement\_group\_id) | n/a | `number` | `null` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | n/a | `string` | n/a | yes |
| <a name="input_protect"></a> [protect](#input\_protect) | n/a | `bool` | `true` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | Rancher roles: etcd, controlplane, worker. Never pass --taints for etcd/controlplane (tg-env lesson: Rancher sets them, a duplicate crashes the kubelet) | `list(string)` | n/a | yes |
| <a name="input_server_type"></a> [server\_type](#input\_server\_type) | n/a | `string` | n/a | yes |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | n/a | `list(string)` | `[]` | no |
| <a name="input_write_files"></a> [write\_files](#input\_write\_files) | n/a | <pre>list(object({<br/>    path        = string<br/>    content     = string<br/>    permissions = optional(string, "0644")<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | n/a |
<!-- END_TF_DOCS -->
