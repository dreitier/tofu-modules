variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "oidc_provider_arn" {
  type        = string
  description = "IAM OIDC provider of the cluster (output provider_arn of aws-oidc-issuer)"
}

variable "oidc_provider_host" {
  type        = string
  description = "Issuer without scheme (output provider_host of aws-oidc-issuer)"
}

variable "roles" {
  type = map(object({
    namespace           = string
    service_account     = string
    policy_json         = optional(string)
    managed_policy_arns = optional(list(string), [])
    description         = optional(string, "")
  }))
  description = "IAM roles for service accounts, keyed by role name; each trusts exactly one service account"
}
