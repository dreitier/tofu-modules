# fintier

fintier (dreitier/fintier): finance dashboard from DATEV BWA/SuSa PDFs. FastAPI + PostgreSQL, VPN only
(internal Traefik, wildcard certificate *.intern.<domain>), login via Keycloak (client fintier, restricted
to the access group – the application checks the "groups" claim as well).
Secrets are never environment variables: one ExternalSecret renders one file per secret, mounted read-only
at /run/secrets (the application's SECRETS_DIR):
```text
  data_key, session_key   <keys_kv_name>  (scripts/fintier-keys.sh, write once – data_key encrypts every
                                           stored BWA/SuSa: losing it makes all data unreadable)
  db_password             <db_kv_name>    (config/openbao-base, data/postgresql)
  oidc_client_secret      <oidc_kv_name>  (config/keycloak, client fintier)
```
The image is a private GHCR package → pull secret from <pull_kv_name> (shared with verschreibomat).
The application reads the secrets at startup only: after a rotation restart the Deployment.
The PDF import worker runs inside the application process. One replica; RollingUpdate is safe: the worker
claims a job with SELECT … FOR UPDATE SKIP LOCKED inside its transaction (two pods never take the same
job, a pod killed mid-import rolls back and the job stays queued), sessions are signed cookies with the
shared session_key, and the schema exists already when the second pod starts (CREATE TABLE IF NOT EXISTS).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_group"></a> [access\_group](#input\_access\_group) | Keycloak group (name in the groups claim) whose members may use fintier – same as the client's access\_groups in config/keycloak | `string` | n/a | yes |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | n/a | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | n/a | `string` | `"k8s/prod/postgresql-fintier"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | database and role are named fintier in the application (not configurable there) | `string` | `"fintier"` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Internal hostname (VPN), e.g. fintier.intern.<domain> | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Image incl. tag, e.g. ghcr.io/dreitier/fintier:2.0.0 (private package → pull secret) | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | n/a | `string` | n/a | yes |
| <a name="input_keys_kv_name"></a> [keys\_kv\_name](#input\_keys\_kv\_name) | OpenBao entry with data\_key and session\_key (scripts/fintier-keys.sh, write once) | `string` | `"k8s/prod/fintier"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit); null = in-cluster service account (CI) | `string` | `null` | no |
| <a name="input_local_login"></a> [local\_login](#input\_local\_login) | Break-glass login with local users (created with python -m app.cli create-user); without such users the form is inert | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"fintier"` | no |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | `"fintier"` | no |
| <a name="input_oidc_kv_name"></a> [oidc\_kv\_name](#input\_oidc\_kv\_name) | n/a | `string` | `"k8s/prod/oidc/fintier"` | no |
| <a name="input_oidc_label"></a> [oidc\_label](#input\_oidc\_label) | Text of the SSO button ("Anmelden mit …") | `string` | `"dreitier-Konto"` | no |
| <a name="input_pull_kv_name"></a> [pull\_kv\_name](#input\_pull\_kv\_name) | OpenBao entry with username + token (classic PAT, read:packages) for ghcr.io | `string` | `"k8s/prod/ghcr-pull"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | <pre>object({<br/>    requests = map(string)<br/>    limits   = map(string)<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "memory": "768Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "50m",<br/>    "memory": "256Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_url"></a> [url](#output\_url) | n/a |
<!-- END_TF_DOCS -->
