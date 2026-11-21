# aws-irsa-roles

IAM roles for service accounts (IRSA, docs/irsa.md). Each role trusts exactly one Kubernetes service
account of the cluster behind the OIDC provider (sub = system:serviceaccount:<ns>:<sa>, aud = STS).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | IAM OIDC provider of the cluster (output provider\_arn of aws-oidc-issuer) | `string` | n/a | yes |
| <a name="input_oidc_provider_host"></a> [oidc\_provider\_host](#input\_oidc\_provider\_host) | Issuer without scheme (output provider\_host of aws-oidc-issuer) | `string` | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | IAM roles for service accounts, keyed by role name; each trusts exactly one service account | <pre>map(object({<br/>    namespace           = string<br/>    service_account     = string<br/>    policy_json         = optional(string)<br/>    managed_policy_arns = optional(list(string), [])<br/>    description         = optional(string, "")<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | Role ARNs for AWS\_ROLE\_ARN of the consumers |
<!-- END_TF_DOCS -->
