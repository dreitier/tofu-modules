# kyverno

Kyverno policy engine (installs the CRDs via its kyverno-api sub-chart). Policies live in the separate unit
security/kyverno-policies (modules/kyverno-policies) – CRDs and CRs are never in the same unit.
Kyverno >= 1.20 only knows the CEL policy types (policies.kyverno.io: ValidatingPolicy,
ImageValidatingPolicy, MutatingPolicy, ...); ClusterPolicy/Policy are gone. See docs/kyverno.md.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admission_replicas"></a> [admission\_replicas](#input\_admission\_replicas) | Replicas of the admission controller (>1 also creates a PDB) | `number` | `2` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Kyverno chart version (oci://ghcr.io/kyverno/charts/kyverno; 3.10.x = Kyverno 1.20.x) | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | ServiceMonitors, PrometheusRule and Grafana dashboard – needs the Prometheus Operator CRDs (monitoring.coreos.com) | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"kyverno"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources per controller – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key kyverno) | <pre>object({<br/>    admission_controller  = optional(any, { requests = { cpu = "100m", memory = "128Mi" }, limits = { memory = "384Mi" } })<br/>    background_controller = optional(any, { requests = { cpu = "100m", memory = "64Mi" }, limits = { memory = "128Mi" } })<br/>    cleanup_controller    = optional(any, { requests = { cpu = "100m", memory = "64Mi" }, limits = { memory = "128Mi" } })<br/>    reports_controller    = optional(any, { requests = { cpu = "100m", memory = "128Mi" }, limits = { memory = "256Mi" } })<br/>  })</pre> | `{}` | no |
| <a name="input_webhook_excluded_namespaces"></a> [webhook\_excluded\_namespaces](#input\_webhook\_excluded\_namespaces) | Namespaces the Kyverno webhooks never see (the kyverno namespace is excluded by the chart anyway) | `list(string)` | <pre>[<br/>  "kube-system"<br/>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
