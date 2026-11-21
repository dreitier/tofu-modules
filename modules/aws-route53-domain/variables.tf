variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared config profile (config/globals/aws.tfvars)"
}

variable "domain" {
  type = string
}

variable "zone_id" {
  type        = string
  default     = null
  description = "Existing hosted zone → import (zone and records); null = create"
}

variable "comment" {
  type    = string
  default = "HostedZone created by Route53 Registrar"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "registered" {
  type        = bool
  default     = true
  description = "Domain is registered with Route53 (manage auto renew, transfer lock, name servers)"
}

variable "auto_renew" {
  type    = bool
  default = true
}

variable "contact_privacy" {
  type        = bool
  default     = true
  description = "Hide the contact details in WHOIS (admin, billing, registrant, tech)"
}

variable "transfer_lock" {
  type    = bool
  default = true
}

variable "records" {
  type = map(object({
    name    = string # relative to the domain, "" = apex
    type    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default     = {}
  description = "Records by a stable key (e.g. apex-mx)"
}
