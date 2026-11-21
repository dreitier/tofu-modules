terraform {
  # Ephemeral resources in provider configuration
  required_version = ">= 1.11"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.13"
    }
  }
}
