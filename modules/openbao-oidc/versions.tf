terraform {
  # Ephemeral resources and write-only attributes
  required_version = ">= 1.11"
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.13"
    }
  }
}
