# External Secrets Operator (installs its CRDs). The ClusterSecretStore lives in the separate unit
# platform/secret-store (CRDs must exist at plan time); it authenticates with the operator's service
# account against OpenBao's kubernetes auth method.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

# Extra CA for the Vault server's certificate (only when Vault is reached via an internal HTTPS name)
resource "kubernetes_secret_v1" "ca" {
  count = var.ca_bundle_pem == null ? 0 : 1

  metadata {
    name      = "vault-ca"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  data = {
    "ca.crt" = var.ca_bundle_pem
  }
}

resource "helm_release" "this" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version

  values = [yamlencode(merge(
    {
      installCRDs    = true
      resources      = var.resources.controller
      certController = { resources = var.resources.cert_controller }
      webhook        = { resources = var.resources.webhook }
    },
    # Go reads every file in /etc/ssl/certs – the CA is added to the system pool
    [for c in kubernetes_secret_v1.ca : {
      extraVolumes      = [{ name = "vault-ca", secret = { secretName = c.metadata[0].name } }]
      extraVolumeMounts = [{ name = "vault-ca", mountPath = "/etc/ssl/certs/vault-ca.crt", subPath = "ca.crt", readOnly = true }]
    }]...
  ))]

  timeout = 600

  # Everything secret-related depends on it
  lifecycle {
    prevent_destroy = true
  }
}
