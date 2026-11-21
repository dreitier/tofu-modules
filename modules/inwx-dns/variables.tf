variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "domain" {
  type        = string
  description = "Main domain at INWX"
}

variable "acme_zone_label" {
  type        = string
  default     = "acme"
  description = "Label of the delegated ACME zone below the domain"
}

variable "acme_name_servers" {
  type        = list(string)
  description = "Name servers of the Route53 ACME zone (output name_servers of aws/route53-acme)"
}

variable "acme_challenge_names" {
  type        = list(string)
  default     = []
  description = "Names that get a DNS-01 CNAME into the ACME zone, e.g. intern.example.com (covers *.intern.example.com)"
}

variable "records" {
  type = map(object({
    name    = string
    type    = string
    content = string
    ttl     = optional(number, 3600)
  }))
  default     = {}
  description = "Further records without a producer elsewhere (MX, SPF, DMARC, CAA, …)"
}

variable "imports" {
  type        = map(string)
  default     = {}
  description = "Existing records to import: key of var.records → \"<domain>:<record id>\" (scripts/inwx-records.sh)"
}
