# Hetzner CSI driver (block volumes, StorageClass hcloud-volumes as default). Uses the Secret "hcloud"
# of platform/hcloud-ccm. Volumes are zonal (location of the node) and ReadWriteOnce.

resource "helm_release" "this" {
  name       = "hcloud-csi"
  namespace  = "kube-system"
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-csi"
  version    = var.chart_version

  values = [yamlencode({
    storageClasses = [{
      name                = "hcloud-volumes"
      defaultStorageClass = true
      reclaimPolicy       = "Retain"
    }]
  })]
}
