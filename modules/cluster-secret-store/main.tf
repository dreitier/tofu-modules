# ClusterSecretStore "openbao" – all ExternalSecrets in the cluster refer to it by name.
# Auth: OpenBao's kubernetes auth method with the operator's own service account (config/openbao).
# Changed from tg-env, where an AppRole secret ID had to be created by hand: nothing manual here.

resource "kubernetes_manifest" "openbao" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.name
    }
    spec = {
      provider = {
        # OpenBao speaks the Vault API
        vault = {
          server   = var.openbao_server
          path     = var.kv_mount
          version  = "v2"
          caBundle = var.ca_bundle_pem == null ? null : base64encode(var.ca_bundle_pem)
          auth = {
            kubernetes = {
              mountPath = var.auth_mount
              role      = var.auth_role
              serviceAccountRef = {
                name      = var.service_account.name
                namespace = var.service_account.namespace
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
