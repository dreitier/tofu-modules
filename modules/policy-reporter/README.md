# policy-reporter

Policy Reporter (kyverno/policy-reporter): reads the PolicyReports of Kyverno, serves a UI and Prometheus
metrics. UI internal (VPN) at policy-reporter.<internal_domain>, login via Keycloak (client policy-reporter,
restricted to infrastruktur_SG there). Grafana dashboards via the sidecar. See docs/kyverno.md.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Policy Reporter chart version (oci://ghcr.io/kyverno/charts/policy-reporter) | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_internal_domain"></a> [internal\_domain](#input\_internal\_domain) | Internal (VPN) domain – UI at policy-reporter.<internal\_domain> | `string` | n/a | yes |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | `"dreitier"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | Keycloak base URL, e.g. https://idp.dreitier.com | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | ServiceMonitor and Grafana dashboards – needs the Prometheus Operator CRDs (monitoring.coreos.com) | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"policy-reporter"` | no |
| <a name="input_oidc_kv_name"></a> [oidc\_kv\_name](#input\_oidc\_kv\_name) | Keycloak client secret (config/keycloak, client policy-reporter: client\_id, client\_secret) | `string` | `"k8s/prod/oidc/policy-reporter"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key policy\_reporter) | <pre>object({<br/>    core           = optional(any, { requests = { cpu = "20m", memory = "64Mi" }, limits = { memory = "256Mi" } })<br/>    ui             = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })<br/>    kyverno_plugin = optional(any, { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "128Mi" } })<br/>  })</pre> | `{}` | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
