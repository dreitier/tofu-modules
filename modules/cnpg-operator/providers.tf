provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_ca_certificate
  insecure               = local.kubernetes_insecure
  client_certificate     = local.kubernetes_client_cert
  client_key             = local.kubernetes_client_key
  token                  = local.kubernetes_token

  # Rancher writes its own metadata (namespace status, project assignment) – never manage it here
  ignore_annotations = ["^cattle\\.io/", "^lifecycle\\.cattle\\.io/", "^field\\.cattle\\.io/", "^management\\.cattle\\.io/"]
  ignore_labels      = ["^field\\.cattle\\.io/", "^cattle\\.io/"]
}

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
