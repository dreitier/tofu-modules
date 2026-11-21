# hcloud-ccm

Hetzner Cloud Controller Manager: node initialization (cloud-provider-name external in the cluster
unit), load balancers for LoadBalancer Services (load-balancer.hetzner.cloud/* annotations).
Routes stay with the CNI (Calico encapsulation) – the CCM's route controller is off.
The API token goes write-only into the Secret: never in the state.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_cluster_cidr"></a> [cluster\_cidr](#input\_cluster\_cidr) | n/a | `string` | `"10.42.0.0/16"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Default location of the load balancers | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Private network (output network\_name of hetzner/<env>/network) | `string` | n/a | yes |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_token_revision"></a> [token\_revision](#input\_token\_revision) | Bump after rotating hcloud\_token in SOPS (write-only data is only re-sent on a new revision) | `number` | `1` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
