variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "organization_id" {
  type        = string
  default     = null
  description = "ID of the existing organization (o-…) → import; null = create"
}

variable "organization_service_access_principals" {
  type        = list(string)
  description = "AWS services with trusted access to the organization (aws organizations list-aws-service-access-for-organization) – removing one breaks that service (e.g. sso.amazonaws.com = Identity Center)"
}

variable "organization_policy_types" {
  type    = list(string)
  default = ["SERVICE_CONTROL_POLICY"]
}

variable "budgets" {
  type = map(object({
    import            = optional(bool, true)
    limit_amount      = string
    limit_unit        = optional(string, "USD")
    time_period_start = string # YYYY-MM-DD_hh:mm (UTC)
    time_period_end   = optional(string)
    include_credit    = optional(bool, false)
    include_refund    = optional(bool, false)
    notifications = optional(list(object({
      type              = optional(string, "ACTUAL") # ACTUAL | FORECASTED
      threshold_percent = number
      emails            = list(string)
    })), [])
  }))
  default     = {}
  description = "Monthly cost budgets by name"
}

variable "admin_users" {
  type = map(object({
    import = optional(bool, true)
    tags   = optional(map(string), {})
  }))
  default     = {}
  description = "IAM users with AdministratorAccess (OpenTofu, break-glass)"
}

variable "tofu_role" {
  type = object({
    name = optional(string, "opentofu")
    # Permission sets whose SSO roles may assume it (besides the admin_users)
    trusted_permission_sets = optional(list(string), ["AdministratorAccess"])
  })
  default     = null
  description = "IAM role OpenTofu runs as (profile basement); null = none"
}
