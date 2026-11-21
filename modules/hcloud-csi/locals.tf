locals {
  # Kubeconfig from the cluster unit (Rancher-proxied) – same parsing as modules/monitoring
  kubeconfig = yamldecode(var.kube_config)

  kubeconfig_context_name = try(local.kubeconfig["current-context"], local.kubeconfig.contexts[0].name)
  kubeconfig_context      = one([for c in local.kubeconfig.contexts : c.context if c.name == local.kubeconfig_context_name])
  kubeconfig_cluster      = one([for c in local.kubeconfig.clusters : c.cluster if c.name == local.kubeconfig_context.cluster])
  kubeconfig_user         = one([for u in local.kubeconfig.users : u.user if u.name == local.kubeconfig_context.user])

  kubernetes_host           = local.kubeconfig_cluster.server
  kubernetes_ca_certificate = try(base64decode(local.kubeconfig_cluster["certificate-authority-data"]), null)
  kubernetes_insecure       = try(local.kubeconfig_cluster["insecure-skip-tls-verify"], false)
  kubernetes_client_cert    = try(base64decode(local.kubeconfig_user["client-certificate-data"]), null)
  kubernetes_client_key     = try(base64decode(local.kubeconfig_user["client-key-data"]), null)
  kubernetes_token          = try(local.kubeconfig_user.token, null)
}
