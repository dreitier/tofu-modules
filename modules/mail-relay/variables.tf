variable "kube_config" {
  type      = string
  sensitive = true
}

variable "namespace" {
  type    = string
  default = "mail-relay"
}

variable "release_name" {
  type    = string
  default = "mail-relay"
}

variable "chart_version" {
  type = string
}

variable "relay_host" {
  type        = string
  description = "MX host of the Microsoft 365 tenant (dig MX <domain>), e.g. dreitier-com.mail.protection.outlook.com"
}

variable "myhostname" {
  type        = string
  description = "HELO name / Received header of the relay"
}

variable "relay_networks" {
  type        = list(string)
  default     = ["127.0.0.0/8", "10.42.0.0/16"]
  description = "Clients allowed to relay: the RKE2 pod network (ClusterIP service → connections come from pods)"
}

variable "resources" {
  type = any
  default = {
    requests = { cpu = "10m", memory = "32Mi" }
    limits   = { memory = "128Mi" }
  }
}

variable "allowed_senders" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Envelope sender (MAIL FROM) and header From addresses the relay accepts; everything else is rejected.
    Exchange treats the relay's mail as internal (connector TreatMessagesAsInternal), so without this list any
    pod could send internal mail as any @domain address. [] = no restriction.
  EOT
}
