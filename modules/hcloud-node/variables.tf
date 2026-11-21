variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "image" {
  type = string
}

variable "location" {
  type = string
}

variable "ssh_key_ids" {
  type    = list(string)
  default = []
}

variable "placement_group_id" {
  type    = number
  default = null
}

variable "network_id" {
  type = string
}

variable "network_router_ip" {
  type        = string
  description = "Hetzner's router in the network (first IP of the network range)"
}

variable "private_ip" {
  type = string
}

variable "node_command" {
  type        = string
  sensitive   = true
  description = "Registration command of the cluster unit (output node_command)"
}

variable "roles" {
  type        = list(string)
  description = "Rancher roles: etcd, controlplane, worker. Never pass --taints for etcd/controlplane (tg-env lesson: Rancher sets them, a duplicate crashes the kubelet)"
}

variable "packages" {
  type    = list(string)
  default = []
}

variable "write_files" {
  type = list(object({
    path        = string
    content     = string
    permissions = optional(string, "0644")
  }))
  default = []
}

variable "base_runcmd" {
  type    = list(string)
  default = []
}

variable "protect" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "gateway_ip" {
  type        = string
  description = "Private IP of the gateway: DNS resolver (dnsmasq) of the server (config/globals/hetzner.tfvars)"
}
