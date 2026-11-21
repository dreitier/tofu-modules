# monitoring

Monitoring stack of a cluster (docs/monitoring.md in basement): metrics, logs and alerts, all internal (VPN).
```text
  prometheus.tf  kube-prometheus-stack (Prometheus, Alertmanager → mail via the mail relay, operator,
                 kube-state-metrics, node-exporter), blackbox exporter, own alert rules
  grafana.tf     Grafana, login via Keycloak; dashboards.tf provisions the own dashboards
  loki.tf        Loki single binary, chunks/index in S3-compatible object storage
  alloy.tf       Grafana k8s-monitoring (Alloy): pod logs, node journal, events → Loki; etcd metrics
  secrets.tf     credentials from OpenBao (ClusterSecretStore) – nothing secret in Helm values or the state
```
The resources live in the files named above; this file only describes the module.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alertmanager_pvc_size"></a> [alertmanager\_pvc\_size](#input\_alertmanager\_pvc\_size) | hcloud volumes are at least 10 GB | `string` | `"10Gi"` | no |
| <a name="input_blackbox_exporter_version"></a> [blackbox\_exporter\_version](#input\_blackbox\_exporter\_version) | n/a | `string` | n/a | yes |
| <a name="input_blackbox_targets"></a> [blackbox\_targets](#input\_blackbox\_targets) | Blackbox probes: module (manifests/blackbox-modules.yaml) → URLs | `map(list(string))` | `{}` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Value of the `cluster` label on all metrics and logs | `string` | n/a | yes |
| <a name="input_geoip_init"></a> [geoip\_init](#input\_geoip\_init) | Init container of alloy-logs that downloads the GeoIP database into /geoip (emptyDir), e.g. config/alloy/geoip-download.sh; required when the pod-log stages include config/alloy/traefik-geoip.alloy. null = no GeoIP | <pre>object({<br/>    image  = string<br/>    script = string<br/>  })</pre> | `null` | no |
| <a name="input_grafana_admin_group"></a> [grafana\_admin\_group](#input\_grafana\_admin\_group) | Keycloak group (groups claim) that becomes Grafana admin; Keycloak already limits the client to it | `string` | `"infrastruktur_SG"` | no |
| <a name="input_grafana_admin_kv_name"></a> [grafana\_admin\_kv\_name](#input\_grafana\_admin\_kv\_name) | OpenBao entry with user\_admin\_pass (local break-glass admin, config/openbao-base) | `string` | `"k8s/prod/grafana"` | no |
| <a name="input_grafana_oidc_kv_name"></a> [grafana\_oidc\_kv\_name](#input\_grafana\_oidc\_kv\_name) | Keycloak client secret (config/keycloak, client grafana) | `string` | `"k8s/prod/oidc/grafana"` | no |
| <a name="input_grafana_pvc_size"></a> [grafana\_pvc\_size](#input\_grafana\_pvc\_size) | SQLite database (users, preferences, annotations); dashboards and datasources are provisioned | `string` | `"10Gi"` | no |
| <a name="input_grafana_version"></a> [grafana\_version](#input\_grafana\_version) | n/a | `string` | n/a | yes |
| <a name="input_heartbeat"></a> [heartbeat](#input\_heartbeat) | External heartbeat for the Watchdog alert (healthchecks.io ping URL in OpenBao); null = Watchdog is dropped | <pre>object({<br/>    kv_name     = string<br/>    kv_property = optional(string, "ping_url")<br/>  })</pre> | `null` | no |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_internal_domain"></a> [internal\_domain](#input\_internal\_domain) | Domain of the internal ingresses (grafana.<domain>) | `string` | n/a | yes |
| <a name="input_k8s_monitoring_version"></a> [k8s\_monitoring\_version](#input\_k8s\_monitoring\_version) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | `"dreitier"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | Base URL of Keycloak (https://idp.<domain>) | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | n/a | `string` | n/a | yes |
| <a name="input_kube_prometheus_stack_version"></a> [kube\_prometheus\_stack\_version](#input\_kube\_prometheus\_stack\_version) | n/a | `string` | n/a | yes |
| <a name="input_loki_pvc_size"></a> [loki\_pvc\_size](#input\_loki\_pvc\_size) | WAL and index cache of the single-binary Loki (chunks live in the bucket) | `string` | `"10Gi"` | no |
| <a name="input_loki_retention"></a> [loki\_retention](#input\_loki\_retention) | n/a | `string` | `"30d"` | no |
| <a name="input_loki_s3"></a> [loki\_s3](#input\_loki\_s3) | n/a | <pre>object({<br/>    endpoint = string # https://fsn1.your-objectstorage.com<br/>    region   = string # fsn1<br/>    bucket   = string<br/>    kv_name  = optional(string, "k8s/prod/loki-s3") # access_key, secret_key (Hetzner S3 credentials)<br/>  })</pre> | n/a | yes |
| <a name="input_loki_version"></a> [loki\_version](#input\_loki\_version) | n/a | `string` | n/a | yes |
| <a name="input_mail_from"></a> [mail\_from](#input\_mail\_from) | n/a | `string` | n/a | yes |
| <a name="input_mail_to"></a> [mail\_to](#input\_mail\_to) | n/a | `string` | n/a | yes |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | n/a | <pre>object({<br/>    monitoring = string<br/>    loki       = string<br/>    alloy      = string<br/>  })</pre> | <pre>{<br/>  "alloy": "alloy",<br/>  "loki": "loki",<br/>  "monitoring": "monitoring"<br/>}</pre> | no |
| <a name="input_pod_log_processing_stages"></a> [pod\_log\_processing\_stages](#input\_pod\_log\_processing\_stages) | Alloy stage blocks for pod logs (k8s-monitoring podLogsViaLoki.extraLogProcessingStages), e.g. config/alloy/traefik-logs.alloy | `string` | `""` | no |
| <a name="input_prometheus_pvc_size"></a> [prometheus\_pvc\_size](#input\_prometheus\_pvc\_size) | n/a | `string` | `"20Gi"` | no |
| <a name="input_prometheus_retention"></a> [prometheus\_retention](#input\_prometheus\_retention) | n/a | `string` | `"30d"` | no |
| <a name="input_prometheus_retention_size"></a> [prometheus\_retention\_size](#input\_prometheus\_retention\_size) | Safety net below the volume size – oldest blocks go first | `string` | `"18GB"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "alertmanager": {<br/>    "limits": {<br/>      "memory": "128Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "48Mi"<br/>    }<br/>  },<br/>  "alloy_config_reloader": {<br/>    "limits": {<br/>      "memory": "64Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "32Mi"<br/>    }<br/>  },<br/>  "alloy_logs": {<br/>    "limits": {<br/>      "memory": "384Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "20m",<br/>      "memory": "128Mi"<br/>    }<br/>  },<br/>  "alloy_operator": {<br/>    "limits": {<br/>      "memory": "192Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "64Mi"<br/>    }<br/>  },<br/>  "alloy_singleton": {<br/>    "limits": {<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "20m",<br/>      "memory": "128Mi"<br/>    }<br/>  },<br/>  "blackbox_exporter": {<br/>    "limits": {<br/>      "memory": "100Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "32Mi"<br/>    }<br/>  },<br/>  "grafana": {<br/>    "limits": {<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "50m",<br/>      "memory": "384Mi"<br/>    }<br/>  },<br/>  "grafana_init_chown": {<br/>    "limits": {<br/>      "memory": "32Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "16Mi"<br/>    }<br/>  },<br/>  "grafana_sidecar": {<br/>    "limits": {<br/>      "memory": "192Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "96Mi"<br/>    }<br/>  },<br/>  "kube_state_metrics": {<br/>    "limits": {<br/>      "memory": "192Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "64Mi"<br/>    }<br/>  },<br/>  "loki": {<br/>    "limits": {<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "50m",<br/>      "memory": "256Mi"<br/>    }<br/>  },<br/>  "loki_sidecar": {<br/>    "limits": {<br/>      "memory": "192Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "96Mi"<br/>    }<br/>  },<br/>  "prometheus": {<br/>    "limits": {<br/>      "memory": "2Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "100m",<br/>      "memory": "1Gi"<br/>    }<br/>  },<br/>  "prometheus_config_reloader": {<br/>    "limits": {<br/>      "memory": "64Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "32Mi"<br/>    }<br/>  },<br/>  "prometheus_operator": {<br/>    "limits": {<br/>      "memory": "128Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "48Mi"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |
| <a name="input_smtp_host"></a> [smtp\_host](#input\_smtp\_host) | SMTP relay (platform/mail-relay), port 25 without auth and TLS | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alertmanager_url"></a> [alertmanager\_url](#output\_alertmanager\_url) | n/a |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | n/a |
| <a name="output_loki_url"></a> [loki\_url](#output\_loki\_url) | n/a |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | n/a |
<!-- END_TF_DOCS -->
