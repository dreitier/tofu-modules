# aws-workloads

Workload resources that predate basement: S3 buckets of the applications and the technical IAM users
(static access keys) that access them. Everything here is imported (import = true). Access keys are
deliberately not managed – a key created by OpenTofu would put the secret into the state. New workloads
in the prod cluster use IRSA (aws/irsa-prod) instead of IAM users.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | S3 buckets by name (SSE-S3 default encryption, all public access blocked) | <pre>map(object({<br/>    import              = optional(bool, true)<br/>    bucket_key_enabled  = optional(bool, false)<br/>    versioning          = optional(string) # Enabled | Suspended; null = not managed<br/>    public_access_block = optional(bool, true)<br/>    # false = no public access block exists yet → it is created instead of imported<br/>    import_public_access_block = optional(bool, true)<br/>    # Lifecycle: delete objects (and noncurrent versions) after N days; null = no lifecycle rule managed<br/>    expiration_days = optional(number)<br/>    # Lifecycle: delete only noncurrent versions after N days (current objects stay); ignored when<br/>    # expiration_days is set (that rule covers noncurrent versions too)<br/>    noncurrent_expiration_days = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Customer managed IAM policies by name | <pre>map(object({<br/>    import      = optional(bool, true)<br/>    description = optional(string)<br/>    document    = string # JSON<br/>  }))</pre> | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | Technical IAM users by name. Access keys are not managed (they would end up in the state): create/rotate with the AWS CLI, store in OpenBao. | <pre>map(object({<br/>    import = optional(bool, true)<br/>    # names of var.policies or ARNs of AWS managed policies<br/>    policies = optional(list(string), [])<br/>    # inline policies: name → JSON document<br/>    inline_policies = optional(map(string), {})<br/>    tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arns"></a> [bucket\_arns](#output\_bucket\_arns) | n/a |
| <a name="output_user_arns"></a> [user\_arns](#output\_user\_arns) | n/a |
<!-- END_TF_DOCS -->
