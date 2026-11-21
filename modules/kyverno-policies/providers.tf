provider "helm" {
  kubernetes = {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_ca_certificate
    insecure               = local.kubernetes_insecure
    client_certificate     = local.kubernetes_client_cert
    client_key             = local.kubernetes_client_key
    token                  = local.kubernetes_token
  }
}
