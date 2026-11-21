# ClusterIssuers:
# - letsencrypt-prod: public names via http-01 on the public Traefik (ingress-shim default issuer)
# - letsencrypt-prod-dns: internal names (wildcard *.<internal domain>) via DNS-01. The domain's
#   _acme-challenge records are CNAMEs (INWX) into the dedicated Route53 zone (aws/route53-acme), so
#   cert-manager must follow them (cnameStrategy Follow). No keys: IRSA on the cert-manager controller
#   (ambient credentials, its AWS_REGION applies).

locals {
  issuers = {
    letsencrypt-prod = {
      solvers = [{
        http01 = { ingress = { ingressClassName = var.public_ingress_class } }
      }]
    }
    letsencrypt-prod-dns = {
      solvers = [{
        dns01 = {
          cnameStrategy = "Follow"
          route53       = { hostedZoneID = var.route53_hosted_zone_id }
        }
      }]
    }
  }
}

resource "kubernetes_manifest" "issuer" {
  for_each = { for k, v in local.issuers : k => v if contains(var.issuers, k) }

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = each.key
    }
    spec = {
      acme = {
        email               = var.acme_email
        server              = var.acme_server
        privateKeySecretRef = { name = "${each.key}-account-key" }
        solvers             = each.value.solvers
      }
    }
  }
}
