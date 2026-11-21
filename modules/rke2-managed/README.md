# rke2-managed

Cloud credential used for etcd snapshots to S3. The rancher2 provider has no write-only key
attributes, so Tofu only writes placeholders (ignored afterwards) and the ExternalSecret below
merges the real keys from Vault into the credential's Secret – no AWS keys in the state.
An existing credential can be adopted with:
```text
  terragrunt import 'rancher2_cloud_credential.etcd_s3[0]' cattle-global-data:<cc-id>.<driver>
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_manifest"></a> [additional\_manifest](#input\_additional\_manifest) | Additional manifest deployed to the cluster by RKE2 | `string` | `null` | no |
| <a name="input_agent_tolerations"></a> [agent\_tolerations](#input\_agent\_tolerations) | Additional tolerations of cattle-cluster-agent and fleet-agent | <pre>list(object({<br/>    key      = string<br/>    operator = optional(string, "Equal")<br/>    value    = optional(string)<br/>    effect   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Annotations of the cluster object | `map(string)` | `{}` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Default AWS region (config/globals/aws.tfvars); used for the etcd S3 cloud credential unless set there | `string` | `null` | no |
| <a name="input_chart_values"></a> [chart\_values](#input\_chart\_values) | Values for the RKE2 system charts (chartValues), keyed by chart name | `any` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the downstream cluster in Rancher | `string` | n/a | yes |
| <a name="input_enable_network_policy"></a> [enable\_network\_policy](#input\_enable\_network\_policy) | Enable Rancher project network isolation; null leaves the Rancher default | `bool` | `null` | no |
| <a name="input_etcd"></a> [etcd](#input\_etcd) | etcd snapshot configuration, optionally with an S3 target | <pre>object({<br/>    disable_snapshots      = optional(bool, false)<br/>    snapshot_schedule_cron = optional(string, "0 */5 * * *")<br/>    snapshot_retention     = optional(number, 5)<br/>    s3 = optional(object({<br/>      bucket                = string<br/>      endpoint              = optional(string, "")<br/>      region                = optional(string)<br/>      folder                = optional(string)<br/>      cloud_credential_name = optional(string) # ignored when etcd_s3_credential is set<br/>      endpoint_ca           = optional(string)<br/>      skip_ssl_verify       = optional(bool, false)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_etcd_s3_credential"></a> [etcd\_s3\_credential](#input\_etcd\_s3\_credential) | Rancher cloud credential for the etcd S3 target, managed by this module; keys come from Vault via an ExternalSecret on the local cluster (never in state). null keeps etcd.s3.cloud\_credential\_name | <pre>object({<br/>    name                    = string<br/>    description             = optional(string)<br/>    driver                  = optional(string, "s3")<br/>    region                  = optional(string)<br/>    secret_store            = optional(string, "vault") # ClusterSecretStore on the local cluster<br/>    vault_path              = string                    # path below the store's KV mount<br/>    refresh_interval        = optional(string, "15m")<br/>    access_key_id_field     = optional(string, "access_key_id")<br/>    secret_access_key_field = optional(string, "secret_access_key")<br/>  })</pre> | `null` | no |
| <a name="input_fleet_namespace"></a> [fleet\_namespace](#input\_fleet\_namespace) | Fleet namespace of the cluster | `string` | `"fleet-default"` | no |
| <a name="input_kube_config_token_ttl_seconds"></a> [kube\_config\_token\_ttl\_seconds](#input\_kube\_config\_token\_ttl\_seconds) | TTL of the token in the direct kubeconfig (seconds, 0 = Rancher's maximum) | `number` | `0` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | RKE2 version of the cluster, e.g. v1.33.5+rke2r1 | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels of the cluster object | `map(string)` | `{}` | no |
| <a name="input_local_auth_endpoint"></a> [local\_auth\_endpoint](#input\_local\_auth\_endpoint) | Authorized cluster endpoint (direct access to the downstream API server, bypassing Rancher) | <pre>object({<br/>    enabled  = optional(bool, true)<br/>    fqdn     = optional(string)<br/>    ca_certs = optional(string)<br/>    # Only for the kube_config output (not sent to Rancher): API server URL the platform units use<br/>    # directly, e.g. https://<control plane IP>:6443<br/>    server = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_machine_global_config"></a> [machine\_global\_config](#input\_machine\_global\_config) | RKE2 config applied to all nodes (machineGlobalConfig), e.g. { cni = "canal" } | `any` | `null` | no |
| <a name="input_machine_selector_config"></a> [machine\_selector\_config](#input\_machine\_selector\_config) | RKE2 config applied to nodes matching a label selector (machineSelectorConfig) | <pre>list(object({<br/>    config       = optional(any)<br/>    match_labels = optional(map(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_oidc_kubeconfig"></a> [oidc\_kubeconfig](#input\_oidc\_kubeconfig) | Builds the kube\_config\_oidc output: direct API endpoint + kubelogin exec (no secret). The API server's OIDC flags are set in machine\_global\_config. null = no output | <pre>object({<br/>    issuer_url = string<br/>    client_id  = string<br/>    # Extra arguments of `kubectl oidc-login get-token`, e.g. --listen-address<br/>    extra_args = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_pod_security_admission_template"></a> [pod\_security\_admission\_template](#input\_pod\_security\_admission\_template) | Name of the default Pod Security Admission configuration template (e.g. rancher-restricted) | `string` | `null` | no |
| <a name="input_rancher_admin_user"></a> [rancher\_admin\_user](#input\_rancher\_admin\_user) | Rancher (local provider) user used by OpenTofu | `string` | n/a | yes |
| <a name="input_rancher_ca_cert_pem"></a> [rancher\_ca\_cert\_pem](#input\_rancher\_ca\_cert\_pem) | PEM encoded CA certificate(s) of the Rancher server; null uses the system trust store | `string` | `null` | no |
| <a name="input_rancher_insecure"></a> [rancher\_insecure](#input\_rancher\_insecure) | Skip TLS verification of the Rancher server | `bool` | `false` | no |
| <a name="input_rancher_login_path"></a> [rancher\_login\_path](#input\_rancher\_login\_path) | Path of the Rancher local login endpoint | `string` | `"/v3-public/localProviders/local?action=login"` | no |
| <a name="input_rancher_password_sops_key"></a> [rancher\_password\_sops\_key](#input\_rancher\_password\_sops\_key) | Key inside the SOPS file holding the password of rancher\_admin\_user | `string` | `"admin_password"` | no |
| <a name="input_rancher_token_ttl_minutes"></a> [rancher\_token\_ttl\_minutes](#input\_rancher\_token\_ttl\_minutes) | Lifetime of the token created by the login on every run | `number` | `60` | no |
| <a name="input_rancher_url"></a> [rancher\_url](#input\_rancher\_url) | URL of the Rancher server | `string` | n/a | yes |
| <a name="input_registration_token_name"></a> [registration\_token\_name](#input\_registration\_token\_name) | Name of the cluster registration token created for node\_command (see output registration\_token\_hashes) | `string` | `"node-registration"` | no |
| <a name="input_rotate_certificates_generation"></a> [rotate\_certificates\_generation](#input\_rotate\_certificates\_generation) | Generation of the certificate rotation; increase by one to rotate the cluster certificates | `number` | `null` | no |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS encrypted file containing required secrets | `string` | n/a | yes |
| <a name="input_upgrade_strategy"></a> [upgrade\_strategy](#input\_upgrade\_strategy) | Upgrade strategy of the cluster; defaults match the Rancher defaults | <pre>object({<br/>    control_plane_concurrency = optional(string, "1")<br/>    worker_concurrency        = optional(string, "1")<br/>    control_plane_drain = optional(object({<br/>      enabled                              = optional(bool, false)<br/>      force                                = optional(bool, false)<br/>      ignore_daemon_sets                   = optional(bool, true)<br/>      delete_empty_dir_data                = optional(bool, true)<br/>      disable_eviction                     = optional(bool, false)<br/>      grace_period                         = optional(number, -1)<br/>      timeout                              = optional(number, 120)<br/>      skip_wait_for_delete_timeout_seconds = optional(number, 0)<br/>    }), {})<br/>    worker_drain = optional(object({<br/>      enabled                              = optional(bool, false)<br/>      force                                = optional(bool, false)<br/>      ignore_daemon_sets                   = optional(bool, true)<br/>      delete_empty_dir_data                = optional(bool, true)<br/>      disable_eviction                     = optional(bool, false)<br/>      grace_period                         = optional(number, -1)<br/>      timeout                              = optional(number, 120)<br/>      skip_wait_for_delete_timeout_seconds = optional(number, 0)<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the cluster (c-m-xxxx), as used by most rancher2 resources |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the cluster |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | Kubeconfig of the cluster: the authorized cluster endpoint (direct to the API server) when enabled, otherwise through Rancher |
| <a name="output_kube_config_oidc"></a> [kube\_config\_oidc](#output\_kube\_config\_oidc) | Kubeconfig for people: direct API endpoint, login with kubelogin against the OIDC provider (no secret inside) |
| <a name="output_kube_config_rancher"></a> [kube\_config\_rancher](#output\_kube\_config\_rancher) | Kubeconfig through the Rancher proxy (request size limited – large Helm releases fail) |
| <a name="output_node_command"></a> [node\_command](#output\_node\_command) | Command to register additional nodes with the cluster (append the roles, e.g. --worker) |
| <a name="output_registration_token_hashes"></a> [registration\_token\_hashes](#output\_registration\_token\_hashes) | SHA-256 per registration token name – to match a token from the Rancher UI without revealing it |
<!-- END_TF_DOCS -->
