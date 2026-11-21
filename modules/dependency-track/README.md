# dependency-track

Dependency-Track 5 (api-server monolith + frontend), PostgreSQL in the CNPG cluster (data/postgresql).

- UI and full API internal (VPN) at <internal_hostname>; login via Keycloak (public client, PKCE –
```text
  the SPA gets the token, the api-server validates it against the issuer). Access restricted to
  infrastruktur_SG in Keycloak; OIDC users are provisioned and synced to teams by the groups claim.
```
- Public (public Traefik, Let's Encrypt): ONLY the BOM upload API (/api/v1/bom…) and /api/version at
```text
  <public_hostname>, so GitHub Actions can push SBOMs with a team API key. Everything else answers 404
  there.
```

Secrets (ExternalSecrets from OpenBao, never env vars – the chart mounts them as files):
```text
  <db_kv_name>   password of the role (config/openbao-base, data/postgresql)
  <kek_kv_name>  key encryption key of DT's secret management (scripts/dependency-track-kek.sh)
```
See docs/dependency-track.md.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | dependency-track chart version (https://dependencytrack.github.io/helm-charts; 2.9.x = DT 5.2.x) | `string` | n/a | yes |
| <a name="input_cluster_issuer"></a> [cluster\_issuer](#input\_cluster\_issuer) | n/a | `string` | `"letsencrypt-prod"` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | Read-write service of the CNPG cluster (data/postgresql) | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | OpenBao entry with the role password (property user\_<db\_user>\_pass, config/openbao-base) | `string` | `"k8s/prod/postgresql-dtrack"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | n/a | `string` | `"dtrack"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | n/a | `string` | `"dtrack"` | no |
| <a name="input_internal_hostname"></a> [internal\_hostname](#input\_internal\_hostname) | UI + full API, VPN only, e.g. dependency-track.intern.dreitier.com | `string` | n/a | yes |
| <a name="input_internal_ingress_class"></a> [internal\_ingress\_class](#input\_internal\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_kek_kv_name"></a> [kek\_kv\_name](#input\_kek\_kv\_name) | OpenBao entry with the KEK (property kek, scripts/dependency-track-kek.sh) | `string` | `"k8s/prod/dependency-track"` | no |
| <a name="input_keycloak_realm"></a> [keycloak\_realm](#input\_keycloak\_realm) | n/a | `string` | `"dreitier"` | no |
| <a name="input_keycloak_url"></a> [keycloak\_url](#input\_keycloak\_url) | Keycloak base URL, e.g. https://idp.dreitier.com | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | ServiceMonitor of the api-server – needs the Prometheus Operator CRDs (monitoring.coreos.com) | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"dependency-track"` | no |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | Public Keycloak client (config/keycloak) – used by the frontend and to validate ID tokens | `string` | `"dependency-track"` | no |
| <a name="input_public_hostname"></a> [public\_hostname](#input\_public\_hostname) | BOM upload API only, public, e.g. dependency-track.dreitier.com (A/AAAA → public LB in inwx/dns) | `string` | n/a | yes |
| <a name="input_public_ingress_class"></a> [public\_ingress\_class](#input\_public\_ingress\_class) | Public IngressClass (platform/traefik-public) | `string` | `"traefik"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (key dependency\_track) | <pre>object({<br/>    api_server = optional(any, { requests = { cpu = "250m", memory = "1536Mi" }, limits = { memory = "2Gi" } })<br/>    frontend   = optional(any, { requests = { cpu = "20m", memory = "64Mi" }, limits = { memory = "128Mi" } })<br/>  })</pre> | `{}` | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | n/a | `string` | `"hcloud-volumes"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | n/a | `string` | `"10Gi"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_internal_url"></a> [internal\_url](#output\_internal\_url) | n/a |
| <a name="output_public_url"></a> [public\_url](#output\_public\_url) | Base URL for the BOM upload from CI (only /api/v1/bom and /api/version are routed) |
<!-- END_TF_DOCS -->
