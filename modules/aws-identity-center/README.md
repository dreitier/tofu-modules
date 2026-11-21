# aws-identity-center

IAM Identity Center: Identity Store users/groups, permission sets and their assignments to the AWS account.
Login: SAML via Keycloak (client "aws" in config/keycloak). Provisioning is manual – no SCIM: users,
groups and memberships are managed here, from config/entra/groups.tfvars (stage aws/identity-center).
The SAML NameID (format emailAddress, the user's mail) must equal the Identity Store UserName (= UPN).
docs/aws-sso.md

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assignments"></a> [assignments](#input\_assignments) | Assignments of permission sets to this AWS account | <pre>list(object({<br/>    permission_set = string<br/>    principal_type = string # GROUP | USER<br/>    principal      = string # key of var.groups | key of var.users<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_groups"></a> [groups](#input\_groups) | Identity Store groups by display name (named like the Entra groups they mirror) | <pre>map(object({<br/>    description = optional(string)<br/>    members     = list(string)          # keys of var.users<br/>    import      = optional(bool, false) # exists in the Identity Store (looked up by DisplayName)<br/>  }))</pre> | `{}` | no |
| <a name="input_login_group"></a> [login\_group](#input\_login\_group) | Group whose members may log in (Keycloak access\_groups of the aws client); check: every member of var.groups is in it | `string` | `null` | no |
| <a name="input_permission_sets"></a> [permission\_sets](#input\_permission\_sets) | Permission sets by name | <pre>map(object({<br/>    import_arn          = optional(string) # existing permission set → import<br/>    description         = optional(string)<br/>    session_duration    = optional(string, "PT1H")<br/>    managed_policy_arns = optional(list(string), [])<br/>    inline_policy       = optional(string) # JSON policy document<br/>  }))</pre> | n/a | yes |
| <a name="input_users"></a> [users](#input\_users) | Identity Store users by UserName (= UPN = Keycloak username = SAML NameID) | <pre>map(object({<br/>    display_name = string<br/>    given_name   = string<br/>    family_name  = string<br/>    email        = string<br/>    import       = optional(bool, false) # exists in the Identity Store (looked up by UserName)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_permission_set_arns"></a> [permission\_set\_arns](#output\_permission\_set\_arns) | n/a |
<!-- END_TF_DOCS -->
