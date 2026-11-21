# openbao-server

OpenBao (MPL fork of Vault) in HA mode with integrated storage (Raft). OpenBao dropped most external
storage backends (tg-env's Vault used S3) → Raft on hcloud volumes, snapshots by CronJob (later).
- Auto-unseal with AWS KMS via IRSA: projected service account token + AWS_* env, no static keys
```text
  (same pattern as tg-env, no pod identity webhook)
```
- Self-initialization: on first start OpenBao initializes itself and runs the initialize requests below
```text
  (syntax checked against the OpenBao 2.7 docs, configuration/self-init). Runs once – changes need a
  fresh storage. No root token, no recovery keys are handed out. The only bootstrap/break-glass login is
  kubernetes auth (mount kubernetes-admin) with a short-lived token of the service account
  openbao-admin: BASEMENT_BAO_AUTH=kubernetes BASEMENT_BAO_JWT=$(kubectl -n openbao create token openbao-admin).
  (Cert auth was dropped: Traefik terminates TLS, the client certificate never reaches OpenBao.)
  Everything else: config/openbao-base, config/openbao-oidc.
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_service_account"></a> [admin\_service\_account](#input\_admin\_service\_account) | Service account bound to the self-init admin role (kubernetes auth, mount kubernetes-admin). Fixed at first start. | `string` | `"openbao-admin"` | no |
| <a name="input_anti_affinity_required"></a> [anti\_affinity\_required](#input\_anti\_affinity\_required) | Hard pod anti-affinity (one OpenBao pod per node). false = preference only, for clusters with fewer worker nodes than replicas. | `bool` | `true` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Internal hostname (VPN only) | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_irsa_role_arn"></a> [irsa\_role\_arn](#input\_irsa\_role\_arn) | IAM role of the service account openbao/openbao (aws/irsa-<cluster>) | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key (alias) for auto-unseal (aws/kms-<cluster>-openbao-unseal) | `string` | n/a | yes |
| <a name="input_kms_plugin_image"></a> [kms\_plugin\_image](#input\_kms\_plugin\_image) | OCI image of the AWS KMS seal plugin, pinned by digest (ghcr.io/openbao/openbao-plugin-kms-aws:<tag>@sha256:<digest>) | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Prometheus metrics: telemetry in the server config (unauthenticated /v1/sys/metrics) + ServiceMonitor – needs the Prometheus Operator CRDs. Changing it restarts the pods (rolling, auto-unseal). | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"openbao"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | n/a | `number` | `3` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "512Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "256Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_snapshot"></a> [snapshot](#input\_snapshot) | Raft snapshots to S3 by CronJob; null = off | <pre>object({<br/>    bucket        = string<br/>    role_arn      = string # IRSA role of the service account openbao/openbao-snapshot (PutObject on the bucket)<br/>    schedule      = optional(string, "15 */6 * * *")<br/>    prefix        = optional(string, "openbao")<br/>    auth_mount    = optional(string, "kubernetes") # config/openbao-base<br/>    auth_role     = optional(string, "openbao-snapshot")<br/>    openbao_image = string # bao CLI, same version as the server<br/>    aws_cli_image = string<br/>  })</pre> | `null` | no |
| <a name="input_snapshot_resources"></a> [snapshot\_resources](#input\_snapshot\_resources) | Raft snapshot CronJob: init container (bao) and upload (aws-cli) – every container needs requests + a memory limit (Kyverno require-requests-limits) | <pre>object({<br/>    snapshot = optional(object({ requests = map(string), limits = map(string) }), { requests = { cpu = "10m", memory = "32Mi" }, limits = { memory = "64Mi" } })<br/>    upload   = optional(object({ requests = map(string), limits = map(string) }), { requests = { cpu = "20m", memory = "128Mi" }, limits = { memory = "256Mi" } }) # aws-cli (Python)<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | n/a | `string` | `"hcloud-volumes"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | n/a | `string` | `"10Gi"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
