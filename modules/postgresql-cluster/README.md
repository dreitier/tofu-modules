# postgresql-cluster

Shared PostgreSQL (CloudNativePG cluster), taken from tg-env. Bootstrap: initdb, or a one-time
monolith import (import_source) when migrating databases. Roles get their passwords from OpenBao
(managed roles via ExternalSecrets), backups go to S3 via the Barman Cloud plugin with IRSA
(projected token, no webhook).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alias_service_name"></a> [alias\_service\_name](#input\_alias\_service\_name) | Service name that points to the cluster's rw service (set after the old release is gone) | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | n/a | yes |
| <a name="input_backup_destination"></a> [backup\_destination](#input\_backup\_destination) | s3://bucket/prefix for WAL archive and base backups | `string` | n/a | yes |
| <a name="input_backup_retention"></a> [backup\_retention](#input\_backup\_retention) | n/a | `string` | `"30d"` | no |
| <a name="input_backup_role_arn"></a> [backup\_role\_arn](#input\_backup\_role\_arn) | n/a | `string` | n/a | yes |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | Base backup schedule (6 fields, with seconds) | `string` | `"0 0 22 * * *"` | no |
| <a name="input_backup_server_name"></a> [backup\_server\_name](#input\_backup\_server\_name) | Folder of this cluster below backup\_destination (Barman serverName); null = cluster\_name. Change it<br/>together with a PostgreSQL major upgrade: pg\_upgrade creates a new system ID and restarts at timeline 1,<br/>which must not be mixed into the old archive (runbook postgresql.md, "Major upgrade"). | `string` | `null` | no |
| <a name="input_backup_sidecar_resources"></a> [backup\_sidecar\_resources](#input\_backup\_sidecar\_resources) | Resources of the Barman Cloud plugin sidecar in the instance pods – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18) | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "256Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "20m",<br/>    "memory": "96Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | CNPG cluster name (also its service account → IRSA trust) | `string` | `"pg"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Databases (imported at bootstrap, then adopted as Database CRs) | <pre>map(object({<br/>    owner      = string<br/>    extensions = optional(list(string), []) # created by CNPG (superuser) – e.g. ltree, pgcrypto<br/>  }))</pre> | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | PostgreSQL image (ghcr.io/cloudnative-pg/postgresql, pinned) | `string` | n/a | yes |
| <a name="input_import_source"></a> [import\_source](#input\_import\_source) | Instance to import from at bootstrap (monolith, superuser postgres); null = plain initdb | <pre>object({<br/>    host              = string<br/>    password_property = string<br/>  })</pre> | `null` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | n/a | `number` | `1` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_manage_databases"></a> [manage\_databases](#input\_manage\_databases) | Create Database CRs (false for the first apply – the import must create them) | `bool` | `true` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"db"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "1Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "256Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_role_vault_keys"></a> [role\_vault\_keys](#input\_role\_vault\_keys) | OpenBao KV entry per role (property user\_<role>\_pass) where it differs from vault\_key – one entry per generated\_secrets version, so adding a role doesn't rotate the others | `map(string)` | `{}` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | Login roles (passwords from Vault, managed by CNPG; imported at bootstrap) | `set(string)` | n/a | yes |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"vault"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | n/a | `string` | `"nfs-csi"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | n/a | `string` | `"10Gi"` | no |
| <a name="input_vault_key"></a> [vault\_key](#input\_vault\_key) | Vault KV entry with the role passwords (property user\_<role>\_pass) | `string` | `"infra/k8s/prod/postgresql"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
