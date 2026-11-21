terraform {
  required_version = ">= 1.11"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
  }
}
