# alloy-agent

Grafana k8s-monitoring (Alloy) for a cluster without its own Prometheus/Loki (today: Rancher's local k3s).
Ships to the central Prometheus (remote write) and Loki of the prod cluster through their internal
ingresses (internal Traefik, no login – docs/monitoring.md). Every series and log line gets
cluster=<cluster_label> (destination clusterLabels, chart default).
```text
  logs:    pod logs, node journal, Kubernetes events
  metrics: kubelet, cAdvisor, kube-state-metrics, node-exporter (deployed by the chart), annotated pods
           (k8s.grafana.com/scrape, e.g. Traefik)
```
Job labels as in kube-prometheus-stack (kubelet, kube-state-metrics, node-exporter) and metrics_path on the
kubelet jobs, so its default dashboards and rules cover this cluster too; full metric sets instead of the
chart's allow lists for the same reason.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Value of the `cluster` label on all metrics and logs | `string` | n/a | yes |
| <a name="input_geoip_init"></a> [geoip\_init](#input\_geoip\_init) | Init container of alloy-logs that downloads the GeoIP database into /geoip (emptyDir), e.g. config/alloy/geoip-download.sh; required when the pod-log stages include config/alloy/traefik-geoip.alloy. null = no GeoIP | <pre>object({<br/>    image  = string<br/>    script = string<br/>  })</pre> | `null` | no |
| <a name="input_k8s_monitoring_version"></a> [k8s\_monitoring\_version](#input\_k8s\_monitoring\_version) | n/a | `string` | n/a | yes |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | n/a | `string` | `"infra"` | no |
| <a name="input_loki_url"></a> [loki\_url](#input\_loki\_url) | Base URL of the central Loki, e.g. https://loki.intern.<domain> | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"alloy"` | no |
| <a name="input_openbao_auth_method"></a> [openbao\_auth\_method](#input\_openbao\_auth\_method) | n/a | `string` | `"oidc"` | no |
| <a name="input_openbao_jwt"></a> [openbao\_jwt](#input\_openbao\_jwt) | n/a | `string` | `""` | no |
| <a name="input_openbao_oidc_role"></a> [openbao\_oidc\_role](#input\_openbao\_oidc\_role) | n/a | `string` | `"admin"` | no |
| <a name="input_openbao_url"></a> [openbao\_url](#input\_openbao\_url) | n/a | `string` | n/a | yes |
| <a name="input_pod_log_processing_stages"></a> [pod\_log\_processing\_stages](#input\_pod\_log\_processing\_stages) | Alloy stage blocks for pod logs (k8s-monitoring podLogsViaLoki.extraLogProcessingStages), e.g. config/alloy/traefik-logs.alloy | `string` | `""` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Base URL of the central Prometheus (remote write receiver), e.g. https://prometheus.intern.<domain> | `string` | n/a | yes |
| <a name="input_rancher_token_kv_name"></a> [rancher\_token\_kv\_name](#input\_rancher\_token\_kv\_name) | OpenBao entry with key token: API key (no scope) of the Rancher local user opentofu | `string` | `"tofu/rancher"` | no |
| <a name="input_rancher_url"></a> [rancher\_url](#input\_rancher\_url) | Rancher server URL (config/globals/kubernetes.tfvars) | `string` | n/a | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | <pre>object({<br/>    alloy_logs      = any<br/>    alloy_singleton = any<br/>  })</pre> | <pre>{<br/>  "alloy_logs": {<br/>    "limits": {<br/>      "memory": "512Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "50m",<br/>      "memory": "128Mi"<br/>    }<br/>  },<br/>  "alloy_singleton": {<br/>    "limits": {<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "50m",<br/>      "memory": "256Mi"<br/>    }<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
<!-- END_TF_DOCS -->
