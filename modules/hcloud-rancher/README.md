# hcloud-rancher

Rancher management server: one VM in the private network (no public IP), single-node k3s with Rancher
and cert-manager installed by k3s' Helm controller (manifests in /var/lib/rancher/k3s/server/manifests),
so no Kubernetes provider is needed before the cluster exists. Reachable via VPN only; the RKE2 nodes
register over the private network. TLS: Let's Encrypt via DNS-01 (cert-manager on the VM, manifests in
config/rancher), ingress.tls.source=secret, privateCA=true with the Let's Encrypt roots as cacerts (agent-tls-mode
strict) – docs/rancher-tls.md. Until 2026-11-16 Rancher's own CA (tls.source=rancher).

First login (once): bootstrap password from the VM
```text
  kubectl -n cattle-system get secret bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'
```
then set the admin password, create the local user "opentofu" (rancher_admin_user) and store its
password as rancher_password in SOPS. No password passes through OpenTofu.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cacerts_pem"></a> [cacerts\_pem](#input\_cacerts\_pem) | Rancher's cacerts (Let's Encrypt roots, config/ca/rancher-ca.pem) for the Secret tls-ca | `string` | n/a | yes |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | cert-manager chart version (vX.Y.Z), supported by rancher\_version | `string` | n/a | yes |
| <a name="input_gateway_ip"></a> [gateway\_ip](#input\_gateway\_ip) | Private IP of the gateway: DNS resolver (dnsmasq) of the server (config/globals/hetzner.tfvars) | `string` | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Rancher hostname (server URL), e.g. rancher.intern.example.com – resolves to private\_ip | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | n/a | `string` | `"rocky-9"` | no |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | k3s release (e.g. v1.33.x+k3s1) – must be in the support matrix of rancher\_version | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_letsencrypt_manifest"></a> [letsencrypt\_manifest](#input\_letsencrypt\_manifest) | ClusterIssuer + Certificate for the Rancher ingress (config/rancher/letsencrypt.yaml), applied by k3s | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | n/a | `string` | n/a | yes |
| <a name="input_network_router_ip"></a> [network\_router\_ip](#input\_network\_router\_ip) | Hetzner's router in the network (first IP of the network range) | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | n/a | `string` | n/a | yes |
| <a name="input_protect"></a> [protect](#input\_protect) | n/a | `bool` | `true` | no |
| <a name="input_rancher_version"></a> [rancher\_version](#input\_rancher\_version) | Rancher chart version (stable repo) | `string` | n/a | yes |
| <a name="input_server_type"></a> [server\_type](#input\_server\_type) | n/a | `string` | `"cpx32"` | no |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | n/a | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | n/a |
| <a name="output_url"></a> [url](#output\_url) | n/a |
<!-- END_TF_DOCS -->
