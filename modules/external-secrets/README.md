# external-secrets

External Secrets Operator (installs its CRDs). The ClusterSecretStore lives in the separate unit
platform/secret-store (CRDs must exist at plan time); it authenticates with the operator's service
account against OpenBao's kubernetes auth method.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ca_bundle_pem"></a> [ca\_bundle\_pem](#input\_ca\_bundle\_pem) | Additional CA (PEM) trusted by the operator, e.g. for Vault behind a FreeIPA certificate | `string` | `null` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | external-secrets chart version (keep the deployed one for the import, upgrade separately) | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"external-secrets"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18) | <pre>object({<br/>    controller      = optional(any, { requests = { cpu = "10m", memory = "64Mi" }, limits = { memory = "128Mi" } })<br/>    cert_controller = optional(any, { requests = { cpu = "10m", memory = "96Mi" }, limits = { memory = "192Mi" } })<br/>    webhook         = optional(any, { requests = { cpu = "10m", memory = "48Mi" }, limits = { memory = "96Mi" } })<br/>  })</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
