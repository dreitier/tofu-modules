# Runner scale sets of dreitier/basement for the OpenTofu deployments of our own apps (docs/ci-deploy.md):
#   basement-plan   service account tofu-apps-plan:  read-only on the app namespaces
#   basement-apply  service account tofu-apps-apply: role tofu-app in the app namespaces
# The Kubernetes rights belong to the runner pod's service account (the provider's in-cluster config); AWS
# (state, passphrase) comes from GitHub OIDC (aws/github-actions). Jobs run directly in the runner image
# (ghcr.io/dreitier/actions-runner-tofu) – no container mode, no Docker, Pod Security "restricted".
# Namespace: created by platform/arc-controller (Pod Security "restricted" enforced).
# GitHub App (installed on basement only): OpenBao <github_app_kv_name> (app_id, installation_id, private_key).

locals {
  github_secret = "arc-github-app"

  # exactly what the app modules manage (checked 2026-11-20 for fintier/verschreibomat)
  app_rules = [
    { api_groups = ["apps"], resources = ["deployments"] },
    { api_groups = [""], resources = ["services", "configmaps"] },
    { api_groups = ["networking.k8s.io"], resources = ["ingresses"] },
    { api_groups = ["external-secrets.io"], resources = ["externalsecrets"] },
    { api_groups = ["monitoring.coreos.com"], resources = ["servicemonitors"] },
  ]
  verbs = {
    plan  = ["get", "list", "watch"]
    apply = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  # the modules manage their namespace object (labels) – never create or delete one
  namespace_verbs = {
    plan  = ["get"]
    apply = ["get", "update", "patch"]
  }

  scale_sets = { for k, v in var.scale_sets : k => merge(v, { service_account = "tofu-apps-${k}" }) }

  bindings = merge([
    for k in keys(local.scale_sets) : { for ns in var.app_namespaces : "${k}/${ns}" => { kind = k, namespace = ns } }
  ]...)
}

resource "kubernetes_manifest" "github_app" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = local.github_secret, namespace = var.namespace }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.github_secret, creationPolicy = "Owner" }
      data = [
        { secretKey = "github_app_id", remoteRef = { key = var.github_app_kv_name, property = "app_id" } },
        { secretKey = "github_app_installation_id", remoteRef = { key = var.github_app_kv_name, property = "installation_id" } },
        { secretKey = "github_app_private_key", remoteRef = { key = var.github_app_kv_name, property = "private_key" } },
      ]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

# --- Service accounts and RBAC ------------------------------------------------------------------------

resource "kubernetes_service_account_v1" "runner" {
  for_each = local.scale_sets

  metadata {
    name      = each.value.service_account
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_v1" "app" {
  for_each = local.scale_sets

  metadata {
    name = "tofu-app-${each.key}"
  }

  dynamic "rule" {
    for_each = local.app_rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = local.verbs[each.key]
    }
  }
}

# ClusterRole bound per namespace with a RoleBinding → rights only inside the app namespaces
resource "kubernetes_role_binding_v1" "app" {
  for_each = local.bindings

  metadata {
    name      = "tofu-app-${each.value.kind}"
    namespace = each.value.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.app[each.value.kind].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.runner[each.value.kind].metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_v1" "namespaces" {
  for_each = local.scale_sets

  metadata {
    name = "tofu-app-namespaces-${each.key}"
  }
  rule {
    api_groups     = [""]
    resources      = ["namespaces"]
    resource_names = var.app_namespaces
    verbs          = local.namespace_verbs[each.key]
  }
  # kubernetes_manifest looks up the CRD of every manifest kind (ExternalSecret, ServiceMonitor) – read-only,
  # schemas only
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "namespaces" {
  for_each = local.scale_sets

  metadata {
    name = "tofu-app-namespaces-${each.key}"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.namespaces[each.key].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.runner[each.key].metadata[0].name
    namespace = var.namespace
  }
}

# --- Runner scale sets --------------------------------------------------------------------------------

resource "helm_release" "scale_set" {
  for_each = local.scale_sets

  name       = "basement-${each.key}" # = runs-on label
  namespace  = var.namespace
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.chart_version

  values = [yamlencode({
    githubConfigUrl    = var.github_config_url
    githubConfigSecret = local.github_secret
    minRunners         = 0
    maxRunners         = each.value.max_runners
    # the controller watches only this namespace – no lookup of its deployment
    controllerServiceAccount = var.controller_service_account

    listenerTemplate = {
      spec = {
        containers = [{
          name = "listener"
          securityContext = {
            allowPrivilegeEscalation = false
            runAsNonRoot             = true
            capabilities             = { drop = ["ALL"] }
            seccompProfile           = { type = "RuntimeDefault" }
          }
        }]
      }
    }

    template = {
      spec = {
        serviceAccountName = each.value.service_account
        securityContext = {
          runAsNonRoot   = true
          runAsUser      = 1001
          runAsGroup     = 1001
          fsGroup        = 1001
          seccompProfile = { type = "RuntimeDefault" }
        }
        containers = [{
          name    = "runner"
          image   = var.runner_image
          command = ["/home/runner/run.sh"]
          securityContext = {
            allowPrivilegeEscalation = false
            capabilities             = { drop = ["ALL"] }
          }
          resources = var.runner_resources
        }]
      }
    }
  })]

  depends_on = [
    kubernetes_manifest.github_app,
    kubernetes_role_binding_v1.app,
    kubernetes_cluster_role_binding_v1.namespaces,
  ]
}
