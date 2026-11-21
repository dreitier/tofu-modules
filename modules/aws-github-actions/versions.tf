terraform {
  # Ephemeral resources and write-only attributes
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
  }
}
