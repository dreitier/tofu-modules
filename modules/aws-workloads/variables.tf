variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "buckets" {
  type = map(object({
    import              = optional(bool, true)
    bucket_key_enabled  = optional(bool, false)
    versioning          = optional(string) # Enabled | Suspended; null = not managed
    public_access_block = optional(bool, true)
    # false = no public access block exists yet → it is created instead of imported
    import_public_access_block = optional(bool, true)
    # Lifecycle: delete objects (and noncurrent versions) after N days; null = no lifecycle rule managed
    expiration_days = optional(number)
    # Lifecycle: delete only noncurrent versions after N days (current objects stay); ignored when
    # expiration_days is set (that rule covers noncurrent versions too)
    noncurrent_expiration_days = optional(number)
  }))
  default     = {}
  description = "S3 buckets by name (SSE-S3 default encryption, all public access blocked)"
}

variable "policies" {
  type = map(object({
    import      = optional(bool, true)
    description = optional(string)
    document    = string # JSON
  }))
  default     = {}
  description = "Customer managed IAM policies by name"
}

variable "users" {
  type = map(object({
    import = optional(bool, true)
    # names of var.policies or ARNs of AWS managed policies
    policies = optional(list(string), [])
    # inline policies: name → JSON document
    inline_policies = optional(map(string), {})
    tags            = optional(map(string), {})
  }))
  default     = {}
  description = "Technical IAM users by name. Access keys are not managed (they would end up in the state): create/rotate with the AWS CLI, store in OpenBao."
}
