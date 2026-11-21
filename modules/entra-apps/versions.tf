terraform {
  required_version = ">= 1.11"
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }
  }
}
