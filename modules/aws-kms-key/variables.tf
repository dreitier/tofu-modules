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

variable "alias" {
  type        = string
  description = "Key alias without the alias/ prefix"
}

variable "description" {
  type = string
}

variable "deletion_window_in_days" {
  type    = number
  default = 30
}
