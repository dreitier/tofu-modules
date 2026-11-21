# keycloak

Keycloak (identity broker for Entra ID; OIDC provider of OpenBao, NetBird and the apps).
Public: NetBird clients and the dashboard log in from the Internet → public IngressClass.
Not the Bitnami chart (tg-env lesson: Bitnami images are frozen) – codecentric keycloakx with the
upstream image, database on the CNPG cluster (data/postgresql), admin password and DB password from
OpenBao via ExternalSecrets.
Upstream image without a custom build: `kc.sh start` builds at startup (KC_DB etc. are build options) –
slower start, no image of our own. Bootstrap admin (KC_BOOTSTRAP_ADMIN_*) is only applied on the very
first start against an empty database; afterwards config/keycloak manages users.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_kv_name"></a> [admin\_kv\_name](#input\_admin\_kv\_name) | n/a | `string` | `"k8s/prod/keycloak"` | no |
| <a name="input_admin_kv_property"></a> [admin\_kv\_property](#input\_admin\_kv\_property) | n/a | `string` | `"user_admin_pass"` | no |
| <a name="input_admin_user"></a> [admin\_user](#input\_admin\_user) | Bootstrap admin of the master realm (first start only) | `string` | `"admin"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | n/a | yes |
| <a name="input_cluster_issuer"></a> [cluster\_issuer](#input\_cluster\_issuer) | n/a | `string` | `"letsencrypt-prod"` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | Read-write service of the CNPG cluster (data/postgresql) | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | n/a | `string` | `"k8s/prod/postgresql"` | no |
| <a name="input_db_kv_property"></a> [db\_kv\_property](#input\_db\_kv\_property) | n/a | `string` | `"user_keycloak_pass"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | n/a | `string` | `"keycloak"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | n/a | `string` | `"keycloak"` | no |
| <a name="input_extra_providers"></a> [extra\_providers](#input\_extra\_providers) | Keycloak extensions (provider JARs), pinned by checksum | <pre>list(object({<br/>    name   = string # file name without .jar<br/>    url    = string<br/>    sha256 = string<br/>  }))</pre> | `[]` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Public hostname of the IdP | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | Public IngressClass (platform/traefik-public) | `string` | `"traefik"` | no |
| <a name="input_init_image"></a> [init\_image](#input\_init\_image) | Image of the init container that downloads the provider JARs (wget, sha256sum) | `string` | `"alpine:3.24"` | no |
| <a name="input_init_resources"></a> [init\_resources](#input\_init\_resources) | Init container that downloads the extra providers – every container needs requests + a memory limit (Kyverno require-requests-limits); sized from the 7-day maxima in Prometheus (2026-11-18) | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "64Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "16Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_keycloak_version"></a> [keycloak\_version](#input\_keycloak\_version) | n/a | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"keycloak"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | n/a | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "1536Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "250m",<br/>    "memory": "768Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
