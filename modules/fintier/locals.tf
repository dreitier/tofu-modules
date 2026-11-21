locals {
  # Kubeconfig from the cluster unit (Rancher-proxied) – same parsing as modules/monitoring. kube_config = null:
  # every provider attribute stays null → the provider uses the in-cluster config of the pod's service
  # account (CI runner, docs/ci-deploy.md)
  kubeconfig = var.kube_config == null ? null : yamldecode(var.kube_config)

  kubeconfig_context_name = try(local.kubeconfig["current-context"], local.kubeconfig.contexts[0].name, null)
  kubeconfig_context      = try(one([for c in local.kubeconfig.contexts : c.context if c.name == local.kubeconfig_context_name]), null)
  kubeconfig_cluster      = try(one([for c in local.kubeconfig.clusters : c.cluster if c.name == local.kubeconfig_context.cluster]), null)
  kubeconfig_user         = try(one([for u in local.kubeconfig.users : u.user if u.name == local.kubeconfig_context.user]), null)

  kubernetes_host           = try(local.kubeconfig_cluster.server, null)
  kubernetes_ca_certificate = try(base64decode(local.kubeconfig_cluster["certificate-authority-data"]), null)
  kubernetes_insecure       = try(local.kubeconfig_cluster["insecure-skip-tls-verify"], null)
  kubernetes_client_cert    = try(base64decode(local.kubeconfig_user["client-certificate-data"]), null)
  kubernetes_client_key     = try(base64decode(local.kubeconfig_user["client-key-data"]), null)
  kubernetes_token          = try(local.kubeconfig_user.token, null)
}
