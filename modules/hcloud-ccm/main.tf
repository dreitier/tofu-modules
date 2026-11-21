# Hetzner Cloud Controller Manager: node initialization (cloud-provider-name external in the cluster
# unit), load balancers for LoadBalancer Services (load-balancer.hetzner.cloud/* annotations).
# Routes stay with the CNI (Calico encapsulation) – the CCM's route controller is off.
# The API token goes write-only into the Secret: never in the state.

resource "kubernetes_secret_v1" "hcloud" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data_wo = {
    token   = ephemeral.sops_file.credentials.data["hcloud_token"]
    network = var.network_name
  }
  data_wo_revision = var.token_revision
}

resource "helm_release" "this" {
  name       = "hcloud-cloud-controller-manager"
  namespace  = "kube-system"
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-cloud-controller-manager"
  version    = var.chart_version

  values = [yamlencode({
    # The chart tolerates control-plane and "uninitialized" only. It must also run on a dedicated etcd +
    # control-plane node (no worker role) and before the CNI is ready – it is the first thing that has to run.
    additionalTolerations = [
      { key = "node-role.kubernetes.io/etcd", operator = "Exists", effect = "NoExecute" },
      { key = "node.kubernetes.io/network-unavailable", operator = "Exists", effect = "NoSchedule" },
    ]
    networking = {
      enabled     = true
      clusterCIDR = var.cluster_cidr
    }
    env = {
      HCLOUD_NETWORK_ROUTES_ENABLED        = { value = "false" }
      HCLOUD_LOAD_BALANCERS_LOCATION       = { value = var.location }
      HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP = { value = "true" }
    }
  })]

  depends_on = [kubernetes_secret_v1.hcloud]
}
