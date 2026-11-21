# cnpg-operator

CloudNativePG operator + Barman Cloud plugin (backups to object storage). The plugin chart needs
cert-manager (mTLS between operator and plugin) and must run in the operator's namespace.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_barman_cloud_chart_version"></a> [barman\_cloud\_chart\_version](#input\_barman\_cloud\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"cnpg-system"` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | Operator and Barman Cloud plugin – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18) | <pre>object({<br/>    operator     = optional(any, { requests = { cpu = "50m", memory = "96Mi" }, limits = { memory = "256Mi" } })<br/>    barman_cloud = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })<br/>  })</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
