# Wildcard certificate *.<internal domain> as default certificate of the internal Traefik (TLSStore
# "default" in its namespace): internal hostnames never show up in Certificate Transparency logs, and
# internal Ingresses need no TLS config of their own. DNS-01 via the Route53 delegation (CNAME at INWX).

resource "kubernetes_manifest" "certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "internal-wildcard"
      namespace = var.namespace
    }
    spec = {
      secretName = "internal-wildcard-tls"
      issuerRef  = { kind = "ClusterIssuer", name = var.issuer }
      dnsNames   = ["*.${var.internal_domain}", var.internal_domain]
    }
  }
}

resource "kubernetes_manifest" "tls_store" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "TLSStore"
    metadata = {
      name      = "default"
      namespace = var.namespace
      # Only the internal Traefik processes CRD objects annotated with its class
      annotations = { "kubernetes.io/ingress.class" = var.ingress_class }
    }
    spec = {
      defaultCertificate = { secretName = "internal-wildcard-tls" }
    }
  }
}
