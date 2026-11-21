terraform {
  required_version = ">= 1.11"
  required_providers {
    # github.com/netbirdio/terraform-provider-netbird – management API of the self-hosted server
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0.11"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.13"
    }
  }
}
