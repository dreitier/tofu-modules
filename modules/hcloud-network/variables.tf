variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "name" {
  type = string
}

variable "ip_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet" {
  type    = string
  default = "10.0.1.0/24"
}

variable "network_zone" {
  type    = string
  default = "eu-central"
}

variable "gateway_ip" {
  type        = string
  description = "Fixed private IP of the gateway server (not .1 – that is Hetzner's router)"
}

variable "vpn_ranges" {
  type        = list(string)
  default     = []
  description = "Client ranges of the VPNs, routed back via the gateway"
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "placement_groups" {
  type    = list(string)
  default = ["controlplane", "worker"]
}

variable "ssh_keys" {
  type        = map(string)
  default     = {}
  description = "Admin SSH public keys by name (created as hcloud_ssh_key, IDs go to all servers)"
}
