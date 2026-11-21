terraform {
  # Ephemeral resources and write-only attributes
  required_version = ">= 1.11"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      # kubernetes_secret_v1.data_wo
      version = "~> 3.0"
    }
    # Server-side apply onto an existing object (kubernetes_manifest + import planned a replacement of
    # the AuthConfig)
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 3.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      # v15 is the first release compatible with Rancher 2.15
      version = ">= 15.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.13"
    }
  }
}
