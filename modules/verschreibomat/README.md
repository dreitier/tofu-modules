# verschreibomat

verschreibomat (dreitier/verschreibomat): timesheets for customers from Moco time entries. Spring Boot,
VPN only (internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak for every user of
the realm (no access group – each user only sees their own data in the application).
Secrets are never environment variables: one ExternalSecret renders them into secrets.yaml, mounted
read-only at /etc/verschreibomat (the image's default VERSCHREIBOMAT_SECRETS_FILE):
```text
  <keys_kv_name>   encryption keys of the users' Moco API keys (scripts/verschreibomat-keys.sh, write once)
  <db_kv_name>     password of the database role (config/openbao-base, data/postgresql)
  <oidc_kv_name>   Keycloak client secret (config/keycloak, client verschreibomat)
```
The image is a private GHCR package → pull secret from <pull_kv_name> (written by hand, docs/verschreibomat.md).
Actuator (health, prometheus) listens on its own port (management, 8081), which the Ingress doesn't route;
the application permits /actuator/prometheus there without login. Scraped by a ServiceMonitor.
Spring reads the secrets file only at startup: after a rotation restart the Deployment.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | n/a | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | n/a | `string` | `"k8s/prod/postgresql-verschreibomat"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | n/a | `string` | `"verschreibomat"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | n/a | `string` | `"verschreibomat"` | no |
| <a name="input_encryption_active_key"></a> [encryption\_active\_key](#input\_encryption\_active\_key) | Id the application encrypts new values with | `string` | `"k1"` | no |
| <a name="input_encryption_key_ids"></a> [encryption\_key\_ids](#input\_encryption\_key\_ids) | Ids of all encryption keys in keys\_kv\_name; old ids stay until no row uses them (README of verschreibomat) | `list(string)` | <pre>[<br/>  "k1"<br/>]</pre> | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Internal hostname (VPN), e.g. verschreibomat.intern.<domain> | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Image incl. tag, e.g. ghcr.io/dreitier/verschreibomat:1.0.0 (private package → pull secret) | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | n/a | `string` | n/a | yes |
| <a name="input_keys_kv_name"></a> [keys\_kv\_name](#input\_keys\_kv\_name) | OpenBao entry with the encryption keys encryption\_key\_<id> (scripts/verschreibomat-keys.sh) | `string` | `"k8s/prod/verschreibomat"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit); null = in-cluster service account (CI) | `string` | `null` | no |
| <a name="input_moco_base_url"></a> [moco\_base\_url](#input\_moco\_base\_url) | API base URL of the Moco account | `string` | `"https://dreitier.mocoapp.com/api/v1"` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create the ServiceMonitor – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"verschreibomat"` | no |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | `"verschreibomat"` | no |
| <a name="input_oidc_kv_name"></a> [oidc\_kv\_name](#input\_oidc\_kv\_name) | n/a | `string` | `"k8s/prod/oidc/verschreibomat"` | no |
| <a name="input_pull_kv_name"></a> [pull\_kv\_name](#input\_pull\_kv\_name) | OpenBao entry with username + token (classic PAT, read:packages) for ghcr.io | `string` | `"k8s/prod/ghcr-pull"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | <pre>object({<br/>    requests = map(string)<br/>    limits   = map(string)<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "memory": "768Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "512Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_url"></a> [url](#output\_url) | n/a |
<!-- END_TF_DOCS -->
