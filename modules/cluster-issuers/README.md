# cluster-issuers

ClusterIssuers:
- letsencrypt-prod: public names via http-01 on the public Traefik (ingress-shim default issuer)
- letsencrypt-prod-dns: internal names (wildcard *.<internal domain>) via DNS-01. The domain's
```text
  _acme-challenge records are CNAMEs (INWX) into the dedicated Route53 zone (aws/route53-acme), so
  cert-manager must follow them (cnameStrategy Follow). No keys: IRSA on the cert-manager controller
  (ambient credentials, its AWS_REGION applies).
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acme_email"></a> [acme\_email](#input\_acme\_email) | n/a | `string` | n/a | yes |
| <a name="input_acme_server"></a> [acme\_server](#input\_acme\_server) | n/a | `string` | `"https://acme-v02.api.letsencrypt.org/directory"` | no |
| <a name="input_issuers"></a> [issuers](#input\_issuers) | ClusterIssuers to create (letsencrypt-prod-dns needs route53\_hosted\_zone\_id and IRSA) | `set(string)` | <pre>[<br/>  "letsencrypt-prod",<br/>  "letsencrypt-prod-dns"<br/>]</pre> | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_public_ingress_class"></a> [public\_ingress\_class](#input\_public\_ingress\_class) | IngressClass of the public Traefik (http-01 solver) | `string` | `"traefik"` | no |
| <a name="input_route53_hosted_zone_id"></a> [route53\_hosted\_zone\_id](#input\_route53\_hosted\_zone\_id) | ACME delegation zone (aws/route53-acme); credentials are ambient (IRSA on the cert-manager controller) | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
