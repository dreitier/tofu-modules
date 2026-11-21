# Private network of the cluster. Nodes have no public IP: every packet leaves through the gateway
# (NAT) – a default route in the network points to it. The VPN client ranges route back to it, too.
# Hetzner Cloud Firewalls only filter public interfaces – inside this network NetworkPolicies and
# host firewalls do the filtering.

resource "hcloud_network" "this" {
  name     = var.name
  ip_range = var.ip_range
  labels   = var.labels

  delete_protection = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet
}

# Egress of all servers without public IP (the gateway masquerades)
resource "hcloud_network_route" "default" {
  network_id  = hcloud_network.this.id
  destination = "0.0.0.0/0"
  gateway     = var.gateway_ip
}

# Return path to VPN clients (plain WireGuard break-glass, NetBird routing peer on the gateway)
resource "hcloud_network_route" "vpn" {
  for_each = toset(var.vpn_ranges)

  network_id  = hcloud_network.this.id
  destination = each.value
  gateway     = var.gateway_ip
}

# Spread placement: nodes of one role on different physical hosts (max. 10 servers per group)
resource "hcloud_placement_group" "this" {
  for_each = toset(var.placement_groups)

  name   = "${var.name}-${each.key}"
  type   = "spread"
  labels = var.labels
}

# Admin SSH keys of the project – referenced by the gateway, Rancher and the nodes at creation
resource "hcloud_ssh_key" "admin" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value
  labels     = var.labels
}
