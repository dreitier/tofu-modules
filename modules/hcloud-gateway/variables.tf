variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "name" {
  type    = string
  default = "gateway"
}

variable "server_type" {
  type    = string
  default = "cpx22"
}

variable "image" {
  type    = string
  default = "debian-13"
}

variable "location" {
  type = string
}

variable "ssh_key_ids" {
  type        = list(string)
  default     = []
  description = "hcloud SSH key names/IDs for the initial login"
}

variable "ssh_source_ips" {
  type        = list(string)
  description = "Admin networks allowed to SSH to the gateway"
}

variable "network_id" {
  type = string
}

variable "network_range" {
  type = string
}

variable "private_ip" {
  type        = string
  description = "Fixed private IP – the target of the network's default route"
}

variable "wireguard_port" {
  type    = number
  default = 51820
}

variable "wireguard_range" {
  type    = string
  default = "10.99.0.0/24"
}

variable "internal_dns_records" {
  type        = map(string)
  default     = {}
  description = "dnsmasq address records for VPN clients: domain → IPv4. A domain covers all its subdomains (address=/<domain>/<ip>), the most specific entry wins."
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "netbird_wireguard_port" {
  type        = number
  default     = 51821
  description = "UDP port of the NetBird client on the gateway (routing peer) – not the break-glass WireGuard port"
}
