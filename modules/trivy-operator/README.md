# trivy-operator

Trivy Operator: continuous in-cluster scans – vulnerabilities and SBOMs of the running images, config audit,
exposed secrets, RBAC and infra assessment, compliance reports (RKE2 CIS, NSA, PSS). Results are CRs
(VulnerabilityReport, ConfigAuditReport, ...) per workload plus Prometheus metrics. Step 3 of the cluster
hardening (docs/trivy-operator.md).

Built-in Trivy server (ClientServer mode): one vulnerability DB in the server's volume instead of a DB
download per scan job. Scan jobs run in this namespace (excluded from the Kyverno policies).

CRDs come from the chart's crds/ directory: Helm installs them on the first install only – on chart
upgrades apply them by hand (docs/trivy-operator.md, Renovate label crd-upgrade).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | trivy-operator chart version (https://aquasecurity.github.io/helm-charts/) | `string` | n/a | yes |
| <a name="input_compliance_specs"></a> [compliance\_specs](#input\_compliance\_specs) | Cluster compliance reports (every 6 h) | `list(string)` | <pre>[<br/>  "rke2-cis-1.24",<br/>  "k8s-nsa-1.0",<br/>  "k8s-pss-baseline-0.1",<br/>  "k8s-pss-restricted-0.1"<br/>]</pre> | no |
| <a name="input_excluded_namespaces"></a> [excluded\_namespaces](#input\_excluded\_namespaces) | Namespaces (glob patterns allowed) that are not scanned | `list(string)` | `[]` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com) | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"trivy-system"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key trivy\_operator) | <pre>object({<br/>    operator     = optional(any, { requests = { cpu = "100m", memory = "512Mi" }, limits = { memory = "1Gi" } })<br/>    trivy_server = optional(any, { requests = { cpu = "200m", memory = "512Mi" }, limits = { memory = "1Gi" } })<br/>    scan_job     = optional(any, { requests = { cpu = "100m", memory = "100M" }, limits = { memory = "500M" } })<br/>  })</pre> | `{}` | no |
| <a name="input_scan_jobs_concurrent_limit"></a> [scan\_jobs\_concurrent\_limit](#input\_scan\_jobs\_concurrent\_limit) | Parallel scan jobs (2 workers – keep it low) | `number` | `3` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | n/a | `string` | `"hcloud-volumes"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | Volume of the built-in Trivy server (vulnerability DB + cache) | `string` | `"5Gi"` | no |
| <a name="input_webhook_url"></a> [webhook\_url](#input\_webhook\_url) | Report webhook (apps/sbomreport-to-dependencytrack output webhook\_url); null = none | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
