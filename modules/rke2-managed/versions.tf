terraform {
  required_version = "~> 1.9"
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      # v15 is the first release compatible with Rancher 2.15
      version = ">= 15.0.0"
    }
  }
}
