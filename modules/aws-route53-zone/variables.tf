variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "zone_name" {
  type        = string
  description = "Delegated zone, e.g. acme.example.com"
}

variable "comment" {
  type    = string
  default = "ACME DNS-01 delegation (CNAME targets of _acme-challenge records)"
}

variable "tags" {
  type    = map(string)
  default = {}
}
