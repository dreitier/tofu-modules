# internal-tls

Wildcard certificate *.<internal domain> as default certificate of the internal Traefik (TLSStore
"default" in its namespace): internal hostnames never show up in Certificate Transparency logs, and
internal Ingresses need no TLS config of their own. DNS-01 via the Route53 delegation (CNAME at INWX).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"traefik-internal"` | no |
| <a name="input_internal_domain"></a> [internal\_domain](#input\_internal\_domain) | n/a | `string` | n/a | yes |
| <a name="input_issuer"></a> [issuer](#input\_issuer) | n/a | `string` | `"letsencrypt-prod-dns"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the internal Traefik | `string` | `"traefik-internal"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
