provider "rancher2" {
  api_url   = var.rancher_url
  token_key = local.rancher_token
  ca_certs  = var.rancher_ca_cert_pem
  insecure  = var.rancher_insecure
}

# Rancher's local (management) cluster through the Rancher API proxy, with the same short-lived login
# token as the rancher2 provider. Only used for objects the rancher2 provider has no resource for.
provider "kubernetes" {
  alias                  = "rancher_local"
  host                   = "${trimsuffix(var.rancher_url, "/")}/k8s/clusters/local"
  token                  = local.rancher_token
  cluster_ca_certificate = var.rancher_insecure ? null : var.rancher_ca_cert_pem
  insecure               = var.rancher_insecure
}
