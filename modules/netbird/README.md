# netbird

NetBird (combined netbird-server: management, signal, relay over WebSocket, embedded IdP/Dex) + dashboard,
own manifests (docs/netbird.md). Public at https://<domain> via the public Traefik:
```text
  gRPC (h2c)  /management.ManagementService/, /signalexchange.SignalExchange/ → Service <name>-grpc
  HTTP/1.1    /api, /oauth2, /relay, /ws-proxy                                → Service <name>-http
  /                                                                           → dashboard
```
STUN runs on the gateway (coturn – Hetzner LBs can't do UDP) → server.stuns, the local STUN is off.
Stores in PostgreSQL (CNPG, databases netbird / netbird_events / netbird_idp). config.yaml with all
secrets is rendered by an ExternalSecret from OpenBao (scripts/netbird-secrets.sh, config/openbao-base).
Login: embedded IdP with Keycloak as connector – added once in the dashboard, then localAuthDisabled.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_issuer"></a> [cluster\_issuer](#input\_cluster\_issuer) | n/a | `string` | `"letsencrypt-prod"` | no |
| <a name="input_dashboard_image"></a> [dashboard\_image](#input\_dashboard\_image) | n/a | `string` | n/a | yes |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | n/a | `string` | `"pg-rw.db.svc"` | no |
| <a name="input_db_kv_name"></a> [db\_kv\_name](#input\_db\_kv\_name) | n/a | `string` | `"k8s/prod/postgresql-netbird"` | no |
| <a name="input_db_kv_property"></a> [db\_kv\_property](#input\_db\_kv\_property) | n/a | `string` | `"user_netbird_pass"` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | n/a | `string` | `"netbird"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Public hostname of NetBird (server and dashboard) | `string` | n/a | yes |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_local_auth_disabled"></a> [local\_auth\_disabled](#input\_local\_auth\_disabled) | true once an IdP user is Owner and the Keycloak connector works (docs/netbird.md runbook) | `bool` | `false` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | n/a | `string` | `"info"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"netbird"` | no |
| <a name="input_owner_email"></a> [owner\_email](#input\_owner\_email) | Initial local owner (created on the first start; password from OpenBao) | `string` | n/a | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | <pre>object({<br/>    server = object({<br/>      requests = map(string)<br/>      limits   = map(string)<br/>    })<br/>    dashboard = object({<br/>      requests = map(string)<br/>      limits   = map(string)<br/>    })<br/>  })</pre> | <pre>{<br/>  "dashboard": {<br/>    "limits": {<br/>      "memory": "128Mi"<br/>    },<br/>    "requests": {<br/>      "cpu": "10m",<br/>      "memory": "32Mi"<br/>    }<br/>  },<br/>  "server": {<br/>    "limits": {<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "100m",<br/>      "memory": "256Mi"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |
| <a name="input_secrets_kv_name"></a> [secrets\_kv\_name](#input\_secrets\_kv\_name) | OpenBao entry of scripts/netbird-secrets.sh (store\_encryption\_key, relay\_auth\_secret, idp\_cookie\_key, owner\_password) | `string` | `"k8s/prod/netbird"` | no |
| <a name="input_server_args"></a> [server\_args](#input\_server\_args) | Arguments of netbird-server (config file path) | `list(string)` | <pre>[<br/>  "--config",<br/>  "/etc/netbird/config.yaml"<br/>]</pre> | no |
| <a name="input_server_image"></a> [server\_image](#input\_server\_image) | Combined netbird-server image (management, signal, relay, embedded IdP) | `string` | n/a | yes |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | n/a | `string` | `"hcloud-volumes"` | no |
| <a name="input_stun_uris"></a> [stun\_uris](#input\_stun\_uris) | External STUN servers (coturn on the gateway), e.g. stun:<ip>:3478 – disables the local STUN | `list(string)` | n/a | yes |
| <a name="input_trusted_peers"></a> [trusted\_peers](#input\_trusted\_peers) | NetBird peer networks whose X-Forwarded-For is trusted (unset = 0.0.0.0/0) | `list(string)` | <pre>[<br/>  "100.64.0.0/10"<br/>]</pre> | no |
| <a name="input_trusted_proxies"></a> [trusted\_proxies](#input\_trusted\_proxies) | CIDRs of the reverse proxies (Traefik pods) – X-Forwarded-For is trusted from them | `list(string)` | <pre>[<br/>  "10.42.0.0/16"<br/>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
