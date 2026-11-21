# psono

Psono password manager (dreitier/helm-charts psono): server + web client + admin portal in the combo
image, VPN only (internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak (OIDC).
Fresh installation – users export/import their data stores from the old instance (docs/migration.md).
All secrets come from OpenBao through one ExternalSecret psono-server-env (chart: server.existingSecret):
```text
  k8s/prod/psono            server keys (scripts/psono-server-keys.sh, written once, never rotated)
  <db_kv_name>              password of the database role (config/openbao-base, data/postgresql)
  <oidc_kv_name>            Keycloak client secret (config/keycloak, client psono)
```
Backups: the database via CNPG (data/postgresql); the chart's gobackup job needs static S3 keys → off.
Fileserver (attachments, var.fileserver): own host on the internal Traefik (the browser talks to it
directly), one amazon_s3 shard via IRSA (no keys), its keys from OpenBao via psono-fileserver-env.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_cleanup_resources"></a> [cleanup\_resources](#input\_cleanup\_resources) | Cron job cleartoken (manage.py in the server image) – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18) | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "256Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "128Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | n/a | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | n/a | `string` | `"k8s/prod/postgresql-psono"` | no |
| <a name="input_db_kv_property"></a> [db\_kv\_property](#input\_db\_kv\_property) | n/a | `string` | `"user_psono_pass"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | n/a | `string` | `"psono"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | n/a | `string` | `"psono"` | no |
| <a name="input_fileserver"></a> [fileserver](#input\_fileserver) | Fileserver (attachments) with one amazon\_s3 shard via IRSA. null = no fileserver (and files disabled in the web client). Keys: scripts/psono-fileserver-keys.sh → OpenBao <keys\_kv\_name> (PSONOFS\_*), which also prints cluster\_id/shard\_id/server\_public\_key (not secret) for these inputs. | <pre>object({<br/>    hostname          = string # e.g. psono-files.intern.<domain> (wildcard certificate, dnsmasq)<br/>    shard_id          = string # from the keys script<br/>    server_public_key = string # the server's PSONO_PUBLIC_KEY (public)<br/>    bucket            = string # S3 bucket of the shard<br/>    role_arn          = string # IRSA role (aws/irsa-prod prod-psono-fileserver)<br/>    aws_region        = optional(string, "eu-central-1")<br/>    keys_kv_name      = optional(string, "k8s/prod/psono-fileserver")<br/>    resources = optional(any, {<br/>      requests = { cpu = "50m", memory = "256Mi" }<br/>      limits   = { memory = "512Mi" }<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Internal hostname (VPN), e.g. passwords.intern.<domain> | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | n/a | `string` | n/a | yes |
| <a name="input_keys_kv_name"></a> [keys\_kv\_name](#input\_keys\_kv\_name) | n/a | `string` | `"k8s/prod/psono"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"psono"` | no |
| <a name="input_oidc_button"></a> [oidc\_button](#input\_oidc\_button) | n/a | `string` | `"Anmelden mit Microsoft"` | no |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | `"psono"` | no |
| <a name="input_oidc_kv_name"></a> [oidc\_kv\_name](#input\_oidc\_kv\_name) | n/a | `string` | `"k8s/prod/oidc/psono"` | no |
| <a name="input_oidc_title"></a> [oidc\_title](#input\_oidc\_title) | n/a | `string` | `"dreitier"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "1536Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "1Gi"<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |
| <a name="input_smtp_host"></a> [smtp\_host](#input\_smtp\_host) | SMTP relay (platform/mail-relay output smtp\_host), port 25 without auth | `string` | `"localhost"` | no |
| <a name="input_user_domain"></a> [user\_domain](#input\_user\_domain) | Domain part of the Psono usernames (= the users' UPN domain) | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
