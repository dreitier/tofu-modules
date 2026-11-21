# Gateway: the only server with a public IP besides the load balancers.
# - NAT for the private network (egress of all nodes: image pulls, Rancher agent, STS/KMS)
# - plain WireGuard as bootstrap/break-glass access (works before the cluster and NetBird exist)
# - later NetBird routing peer for the private network (apps/netbird)
# - DNS for VPN clients and the servers of the private network (dnsmasq on wg0 + private IP): the internal zone resolves to private IPs and never appears in
#   public DNS; everything else is forwarded. The internal names are static (wildcard → internal load
#   balancer with a fixed private IP, plus single hosts), so they can live in the one-shot cloud-init.
# The WireGuard key is generated on the host at first boot – no private key in cloud-init, SOPS or state.
# Single point of failure for egress and VPN: rebuildable from this unit; keep its snapshot policy in mind.

resource "hcloud_firewall" "this" {
  name   = var.name
  labels = var.labels

  rule {
    description = "WireGuard (break-glass)"
    direction   = "in"
    protocol    = "udp"
    port        = tostring(var.wireguard_port)
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "STUN for NetBird clients (coturn, STUN only – Hetzner LBs can't do UDP)"
    direction   = "in"
    protocol    = "udp"
    port        = "3478"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "NetBird routing peer (WireGuard port of the NetBird client, direct P2P connections)"
    direction   = "in"
    protocol    = "udp"
    port        = tostring(var.netbird_wireguard_port)
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "SSH from admin networks only"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.ssh_source_ips
  }
}

resource "hcloud_server" "this" {
  name         = var.name
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = var.ssh_key_ids
  firewall_ids = [hcloud_firewall.this.id]
  labels       = var.labels

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = var.network_id
    ip         = var.private_ip
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    network_range  = var.network_range
    vpn_range      = var.wireguard_range
    wireguard_port = var.wireguard_port
    dns_records    = var.internal_dns_records
    private_ip     = var.private_ip
    netbird_port   = var.netbird_wireguard_port
  })

  delete_protection  = true
  rebuild_protection = true

  lifecycle {
    prevent_destroy = true
    # One-shot first boot (tg-env lesson): later cloud-init changes only affect a rebuilt server
    ignore_changes = [user_data, image, ssh_keys]
  }
}
