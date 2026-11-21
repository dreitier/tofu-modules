# inwx-dns

DNS records of the main domain at INWX. The zone itself exists already and is not managed here (no
inwx_nameserver resource) – only the records below; records created elsewhere (portal, other tools) are
left alone. An existing record with the same name/type is imported instead of duplicated:
```text
  terragrunt import 'inwx_nameserver_record.this["<key>"]' <domain>:<record id>
```
Records next to their producer where possible (tg-env lesson): this unit only holds the delegation,
the ACME CNAMEs and records without a Kubernetes/Hetzner producer.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acme_challenge_names"></a> [acme\_challenge\_names](#input\_acme\_challenge\_names) | Names that get a DNS-01 CNAME into the ACME zone, e.g. intern.example.com (covers *.intern.example.com) | `list(string)` | `[]` | no |
| <a name="input_acme_name_servers"></a> [acme\_name\_servers](#input\_acme\_name\_servers) | Name servers of the Route53 ACME zone (output name\_servers of aws/route53-acme) | `list(string)` | n/a | yes |
| <a name="input_acme_zone_label"></a> [acme\_zone\_label](#input\_acme\_zone\_label) | Label of the delegated ACME zone below the domain | `string` | `"acme"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Main domain at INWX | `string` | n/a | yes |
| <a name="input_imports"></a> [imports](#input\_imports) | Existing records to import: key of var.records → "<domain>:<record id>" (scripts/inwx-records.sh) | `map(string)` | `{}` | no |
| <a name="input_records"></a> [records](#input\_records) | Further records without a producer elsewhere (MX, SPF, DMARC, CAA, …) | <pre>map(object({<br/>    name    = string<br/>    type    = string<br/>    content = string<br/>    ttl     = optional(number, 3600)<br/>  }))</pre> | `{}` | no |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
