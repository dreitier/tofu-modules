# Rancher login via Keycloak (OIDC provider "keycloakoidc"). Only members of var.access_group get in (Keycloak:
# restrict-client-auth on the client; Rancher: accessMode required). var.admin_group → global admin,
# var.access_group → read-only on the listed clusters. The local users (opentofu, admin) keep working.
#
# The client secret must not reach the state, and rancher2_auth_config_keycloak_oidc keeps it as a plain
# attribute. So the AuthConfig object is managed directly in Rancher's local cluster: the Secret that Rancher
# would write itself (cattle-global-data/keycloakoidcconfig-clientsecret) write-only, the AuthConfig with a
# reference to it – the form Rancher stores after a UI/API save.

locals {
  issuer          = "${trimsuffix(var.keycloak_url, "/")}/realms/${var.keycloak_realm}"
  secret_ns       = "cattle-global-data"
  secret_name     = "keycloakoidcconfig-clientsecret"
  group_principal = "keycloakoidc_group://"
}

resource "kubernetes_secret_v1" "client_secret" {
  metadata {
    name      = local.secret_name
    namespace = local.secret_ns
  }

  # Rancher reads the key named after the field; both spellings, as the key's case isn't documented
  data_wo = {
    clientsecret = ephemeral.vault_kv_secret_v2.oidc.data["client_secret"]
    clientSecret = ephemeral.vault_kv_secret_v2.oidc.data["client_secret"]
  }
  data_wo_revision = var.client_secret_version
}

# Rancher creates every AuthConfig (disabled) at startup. Server-side apply sets only the fields below and
# leaves Rancher's own (annotations, logoutAllSupported, status) alone; destroying the resource keeps the object
# (apply_only) – to switch the login off, set enabled = false and apply.
resource "kubectl_manifest" "auth_config" {
  server_side_apply = true
  force_conflicts   = true
  apply_only        = true

  yaml_body = yamlencode({
    apiVersion = "management.cattle.io/v3"
    kind       = "AuthConfig"
    metadata   = { name = "keycloakoidc" }

    type                = "keyCloakOIDCConfig"
    enabled             = true
    accessMode          = "required"
    allowedPrincipalIds = ["${local.group_principal}${var.access_group}"]

    clientId           = var.client_id
    clientSecret       = "${local.secret_ns}:${local.secret_name}"
    issuer             = local.issuer
    authEndpoint       = "${local.issuer}/protocol/openid-connect/auth"
    rancherUrl         = "${trimsuffix(var.rancher_url, "/")}/verify-auth"
    scope              = "openid profile email"
    groupSearchEnabled = false
  })

  depends_on = [kubernetes_secret_v1.client_secret]
}

resource "rancher2_global_role_binding" "admin" {
  name               = "keycloak-${lower(replace(var.admin_group, "_", "-"))}-admin"
  global_role_id     = "admin"
  group_principal_id = "${local.group_principal}${var.admin_group}"

  depends_on = [kubectl_manifest.auth_config]
}

# Read-only without secrets: Kubernetes RBAC can't exclude a resource from "*", so the core group lists its
# resources and every other API group is named (new CRD groups → read_only_api_groups)
resource "rancher2_role_template" "read_only" {
  name        = "Read-only (no secrets)"
  context     = "cluster"
  description = "Read access to the whole cluster except Secrets – basement (rancher-auth)"

  rules {
    api_groups = [""]
    resources = [
      "bindings", "configmaps", "endpoints", "events", "limitranges", "namespaces", "nodes",
      "persistentvolumeclaims", "persistentvolumes", "pods", "pods/log", "pods/status", "replicationcontrollers",
      "resourcequotas", "serviceaccounts", "services",
    ]
    verbs = ["get", "list", "watch"]
  }

  rules {
    api_groups = var.read_only_api_groups
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  # Rancher UI: see the cluster's projects and nodes
  role_template_ids = ["projects-view", "nodes-view"]
}

resource "rancher2_cluster_role_template_binding" "read_only" {
  for_each = toset(var.read_only_cluster_ids)

  name               = "keycloak-${lower(replace(var.access_group, "_", "-"))}-read-only"
  cluster_id         = each.value
  role_template_id   = rancher2_role_template.read_only.id
  group_principal_id = "${local.group_principal}${var.access_group}"

  depends_on = [kubectl_manifest.auth_config]
}
