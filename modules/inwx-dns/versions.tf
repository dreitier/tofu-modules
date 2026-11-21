terraform {
  required_version = ">= 1.11"
  required_providers {
    # github.com/inwx/terraform-provider-inwx (checked 2026-11-10: latest 1.7.1, resource
    # inwx_nameserver_record, import ID <domain>:<record id>)
    inwx = {
      source  = "inwx/inwx"
      version = "~> 1.7"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
  }
}
