variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml), read ephemerally"
}

variable "repository" {
  type        = string
  description = "GitHub repository (owner/name) whose workflows may assume the roles"
}

variable "subject_prefix" {
  type        = string
  default     = null
  description = "Prefix of the OIDC sub claim (sub_claim_prefix of gh api repos/<repo>/actions/oidc/customization/sub); null = repo:<repository>"
}

variable "apply_ref" {
  type        = string
  default     = "refs/heads/main"
  description = "Git ref whose workflow runs (push, workflow_dispatch) get the apply role"
}

variable "state_bucket" {
  type        = string
  description = "State bucket (config/config.hcl state_bucket_name)"
}

variable "automated_units" {
  type        = list(string)
  description = "Unit paths whose states the roles may use (config/config.hcl automated_units)"
}

variable "passphrase_parameter" {
  type        = string
  default     = "/basement/state-passphrase-apps"
  description = "SSM parameter of the automated units' state passphrase"
}

variable "passphrase_sops_key" {
  type    = string
  default = "state_encryption_passphrase_apps"
}

variable "passphrase_version" {
  type        = number
  default     = 1
  description = "Bump after changing the passphrase in SOPS – rewrites the SSM parameter (write-only)"
}
