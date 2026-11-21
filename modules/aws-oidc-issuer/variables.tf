variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket that serves the OIDC discovery document and JWKS (its URL is the issuer)"
}

variable "jwks_json" {
  type        = string
  default     = null
  description = <<-EOT
    JWKS of the cluster's service account signing key (kubectl get --raw /openid/v1/jwks). null on the
    first apply of a new cluster: the issuer URL only depends on the bucket, so the cluster can be
    created with it before the JWKS exists (docs/bootstrap.md).
  EOT

  validation {
    condition     = var.jwks_json == null || length(try(jsondecode(var.jwks_json).keys, [])) > 0
    error_message = "jwks_json must be null or a JWKS document with at least one key."
  }
}

variable "client_ids" {
  type        = list(string)
  default     = ["sts.amazonaws.com"]
  description = "Audiences accepted by the IAM OIDC provider"
}

variable "tags" {
  type    = map(string)
  default = {}
}
