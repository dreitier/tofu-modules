# aws-account

Account-wide settings of the AWS account (management account of a single-account organization):
the organization itself, cost budgets, the IAM users with admin rights (break-glass) and the role OpenTofu
runs as. Everything but the role predates basement and is imported. People log in via IAM Identity Center
(aws/identity-center), the admin users here are the fallback when Keycloak or Identity Center is unavailable. Their access keys
are not managed (they would end up in the state).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_users"></a> [admin\_users](#input\_admin\_users) | IAM users with AdministratorAccess (OpenTofu, break-glass) | <pre>map(object({<br/>    import = optional(bool, true)<br/>    tags   = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_budgets"></a> [budgets](#input\_budgets) | Monthly cost budgets by name | <pre>map(object({<br/>    import            = optional(bool, true)<br/>    limit_amount      = string<br/>    limit_unit        = optional(string, "USD")<br/>    time_period_start = string # YYYY-MM-DD_hh:mm (UTC)<br/>    time_period_end   = optional(string)<br/>    include_credit    = optional(bool, false)<br/>    include_refund    = optional(bool, false)<br/>    notifications = optional(list(object({<br/>      type              = optional(string, "ACTUAL") # ACTUAL | FORECASTED<br/>      threshold_percent = number<br/>      emails            = list(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | ID of the existing organization (o-…) → import; null = create | `string` | `null` | no |
| <a name="input_organization_policy_types"></a> [organization\_policy\_types](#input\_organization\_policy\_types) | n/a | `list(string)` | <pre>[<br/>  "SERVICE_CONTROL_POLICY"<br/>]</pre> | no |
| <a name="input_organization_service_access_principals"></a> [organization\_service\_access\_principals](#input\_organization\_service\_access\_principals) | AWS services with trusted access to the organization (aws organizations list-aws-service-access-for-organization) – removing one breaks that service (e.g. sso.amazonaws.com = Identity Center) | `list(string)` | n/a | yes |
| <a name="input_tofu_role"></a> [tofu\_role](#input\_tofu\_role) | IAM role OpenTofu runs as (profile basement); null = none | <pre>object({<br/>    name = optional(string, "opentofu")<br/>    # Permission sets whose SSO roles may assume it (besides the admin_users)<br/>    trusted_permission_sets = optional(list(string), ["AdministratorAccess"])<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | n/a |
| <a name="output_tofu_role_arn"></a> [tofu\_role\_arn](#output\_tofu\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
