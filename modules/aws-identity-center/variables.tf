variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "users" {
  type = map(object({
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
    import       = optional(bool, false) # exists in the Identity Store (looked up by UserName)
  }))
  default     = {}
  description = "Identity Store users by UserName (= UPN = Keycloak username = SAML NameID)"
}

variable "groups" {
  type = map(object({
    description = optional(string)
    members     = list(string)          # keys of var.users
    import      = optional(bool, false) # exists in the Identity Store (looked up by DisplayName)
  }))
  default     = {}
  description = "Identity Store groups by display name (named like the Entra groups they mirror)"
}

variable "login_group" {
  type        = string
  default     = null
  description = "Group whose members may log in (Keycloak access_groups of the aws client); check: every member of var.groups is in it"
}

variable "permission_sets" {
  type = map(object({
    import_arn          = optional(string) # existing permission set → import
    description         = optional(string)
    session_duration    = optional(string, "PT1H")
    managed_policy_arns = optional(list(string), [])
    inline_policy       = optional(string) # JSON policy document
  }))
  description = "Permission sets by name"
}

variable "assignments" {
  type = list(object({
    permission_set = string
    principal_type = string # GROUP | USER
    principal      = string # key of var.groups | key of var.users
  }))
  default     = []
  description = "Assignments of permission sets to this AWS account"

  validation {
    condition     = alltrue([for a in var.assignments : contains(["GROUP", "USER"], a.principal_type)])
    error_message = "principal_type must be GROUP or USER."
  }
}
