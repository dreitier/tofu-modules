# hcloud-csi

Hetzner CSI driver (block volumes, StorageClass hcloud-volumes as default). Uses the Secret "hcloud"
of platform/hcloud-ccm. Volumes are zonal (location of the node) and ReadWriteOnce.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
