# aws-route53-zone

Dedicated Route53 zone (e.g. acme.example.com) for the ACME DNS-01 delegation: the main domain stays
at INWX, its _acme-challenge records are CNAMEs into this zone. A reusable delegation set keeps the
name servers stable even if the zone is ever recreated (the NS records at INWX would break otherwise).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_comment"></a> [comment](#input\_comment) | n/a | `string` | `"ACME DNS-01 delegation (CNAME targets of _acme-challenge records)"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Delegated zone, e.g. acme.example.com | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | NS records to set at INWX for the delegation |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | n/a |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | n/a |
<!-- END_TF_DOCS -->
