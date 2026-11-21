terraform {
  required_version = ">= 1.11"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
  }
}
