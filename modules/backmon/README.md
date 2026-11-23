# backmon

backmon (dreitier/backmon): monitors the backup files in S3 buckets and exposes Prometheus metrics. Installed
with our own chart (dreitier/helm-charts backmon), VPN only (internal Traefik, wildcard certificate
*.intern.<domain>), no login – backmon has no OIDC; downloads are off, the UI shows names, sizes and dates only.
S3 without keys: IRSA role <role_arn> (aws/irsa-prod, trusts the service account <namespace>/backmon) via a
projected token – backmon falls back to the AWS default credential chain when the environment has no keys.
The role may list the buckets and read their backup_definitions.yaml, nothing else → no bucket discovery
(s3:ListAllMyBuckets), the buckets are listed in disks.include.
Each bucket needs a backup_definitions.yaml in its root; without one backmon reports the disk with
backmon_definition_status = 1.
Alerts: the chart's PrometheusRule (var.alerts_enabled, off by default). Metrics: ServiceMonitor.
The namespace holds no credentials: the chart's Secret is the configuration file (bucket names only).
CI (docs/ci-deploy.md of basement): Helm keeps its release in Secrets of the namespace → the runner needs the
Helm rights of modules/arc-runners (helm_app_namespaces).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alert_rules"></a> [alert\_rules](#input\_alert\_rules) | Overrides of the chart's prometheusRules values (per rule: enabled, thresholds), e.g. { backupSizeChanged = { enabled = false } } | `any` | `{}` | no |
| <a name="input_alerts_enabled"></a> [alerts\_enabled](#input\_alerts\_enabled) | Create the chart's PrometheusRule (backup overdue/missing/size changed, …) – needs monitoring\_enabled | `bool` | `false` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region of the buckets (and of the STS endpoint) | `string` | `"eu-central-1"` | no |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | S3 buckets to monitor (backmon: disks); each needs a backup\_definitions.yaml in its root | `list(string)` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the chart backmon (dreitier/helm-charts) | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Name of the backmon environment (label environment of the metrics) | `string` | `"aws"` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Internal hostname (VPN), e.g. backmon.intern.<domain> | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Image incl. tag, e.g. ghcr.io/dreitier/backmon:6.2.1 (public package) – overrides the chart's image | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit); null = in-cluster service account (CI) | `string` | `null` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | n/a | `string` | `"info"` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create the ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"backmon"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | <pre>object({<br/>    requests = map(string)<br/>    limits   = map(string)<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "memory": "256Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "64Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | IRSA role of the service account <namespace>/backmon (aws/irsa-prod): s3:ListBucket on the buckets, s3:GetObject on their backup\_definitions.yaml | `string` | n/a | yes |
| <a name="input_update_interval"></a> [update\_interval](#input\_update\_interval) | Interval of the bucket scans | `string` | `"15m"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
| <a name="output_url"></a> [url](#output\_url) | n/a |
<!-- END_TF_DOCS -->
