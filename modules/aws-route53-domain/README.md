# aws-route53-domain

A domain registered with Route53 and its hosted zone (created by the registrar), including the records.
Existing domains are imported (zone_id set). The NS and SOA records belong to the zone and are not
managed as records.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_auto_renew"></a> [auto\_renew](#input\_auto\_renew) | n/a | `bool` | `true` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_comment"></a> [comment](#input\_comment) | n/a | `string` | `"HostedZone created by Route53 Registrar"` | no |
| <a name="input_contact_privacy"></a> [contact\_privacy](#input\_contact\_privacy) | Hide the contact details in WHOIS (admin, billing, registrant, tech) | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | n/a | yes |
| <a name="input_records"></a> [records](#input\_records) | Records by a stable key (e.g. apex-mx) | <pre>map(object({<br/>    name    = string # relative to the domain, "" = apex<br/>    type    = string<br/>    ttl     = optional(number, 3600)<br/>    records = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_registered"></a> [registered](#input\_registered) | Domain is registered with Route53 (manage auto renew, transfer lock, name servers) | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_transfer_lock"></a> [transfer\_lock](#input\_transfer\_lock) | n/a | `bool` | `true` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Existing hosted zone → import (zone and records); null = create | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | n/a |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | n/a |
<!-- END_TF_DOCS -->
