terraform {
  required_version = ">= 1.11"
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}
