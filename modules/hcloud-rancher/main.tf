# Rancher management server: one VM in the private network (no public IP), single-node k3s with Rancher
# and cert-manager installed by k3s' Helm controller (manifests in /var/lib/rancher/k3s/server/manifests),
# so no Kubernetes provider is needed before the cluster exists. Reachable via VPN only; the RKE2 nodes
# register over the private network. TLS: Let's Encrypt via DNS-01 (cert-manager on the VM, manifests in
# config/rancher), ingress.tls.source=secret, privateCA=true with the Let's Encrypt roots as cacerts (agent-tls-mode
# strict) – docs/rancher-tls.md. Until 2026-11-16 Rancher's own CA (tls.source=rancher).
#
# First login (once): bootstrap password from the VM
#   kubectl -n cattle-system get secret bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'
# then set the admin password, create the local user "opentofu" (rancher_admin_user) and store its
# password as rancher_password in SOPS. No password passes through OpenTofu.

resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = var.ssh_key_ids
  labels      = var.labels

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = var.network_id
    ip         = var.private_ip
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    router_ip            = var.network_router_ip
    private_ip           = var.private_ip
    hostname             = var.hostname
    k3s_version          = var.k3s_version
    rancher_version      = var.rancher_version
    cert_manager_version = var.cert_manager_version
    resolver_ip          = var.gateway_ip
    letsencrypt_manifest = var.letsencrypt_manifest
    cacerts_pem          = var.cacerts_pem
  })

  delete_protection  = var.protect
  rebuild_protection = var.protect

  lifecycle {
    # Installed once by cloud-init; upgrades of k3s/Rancher happen on the running system
    ignore_changes = [user_data, image, ssh_keys]
  }
}
