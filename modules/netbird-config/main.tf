# NetBird account configuration through the management API (docs/netbird.md). Not in here (no provider
# support or a chicken-and-egg): the Keycloak connector of the embedded IdP and the "User Approval
# Required" switch (dashboard / API, runbook) – both one-time steps.

# JWT group sync: Keycloak's groups claim (Entra groups, e.g. vpn-access_SG, infrastruktur_SG) becomes
# NetBird groups. Groups with the same name must not be created by hand – they would not be synced.
resource "netbird_account_settings" "this" {
  jwt_groups_enabled         = true
  jwt_groups_claim_name      = var.jwt_groups_claim_name
  jwt_allow_groups           = var.jwt_allow_groups
  groups_propagation_enabled = true

  peer_login_expiration_enabled      = true
  peer_login_expiration              = var.peer_login_expiration_hours * 3600
  peer_inactivity_expiration_enabled = false
  peer_inactivity_expiration         = 0

  regular_users_view_blocked          = true
  routing_peer_dns_resolution_enabled = false
  peer_approval_enabled               = false # cloud only

  network_traffic_logs_enabled           = false
  network_traffic_packet_counter_enabled = false
}

# --- Access to the private network ----------------------------------------------------------------
# NetBird "Networks": the routing peer (NetBird client on the gateway, group routing-peers) routes the
# private network with masquerading (Hetzner rejects a route for 100.64.0.0/10). Resources and policies
# decide who reaches what – employees only the internal load balancer and the gateway's DNS, admins the
# whole network. Groups from the JWT sync are looked up by name (never created here: same-name groups
# would not be synced).

data "netbird_group" "jwt" {
  # Every group a policy names must exist in NetBird, i.e. a member has logged in since it appeared in the claim
  for_each = toset(distinct(concat(var.user_groups, var.admin_groups, flatten([for p in values(var.policies) : p.sources]))))
  name     = each.key
}

resource "netbird_group" "routing_peers" {
  name = "routing-peers"
}

# One-off key for the gateway (netbird up --setup-key …, runbook). Rotate: bump setup_key_generation.
resource "netbird_setup_key" "gateway" {
  name           = "gateway-${var.setup_key_generation}"
  type           = "one-off"
  usage_limit    = 1
  expiry_seconds = 86400
  auto_groups    = [netbird_group.routing_peers.id]
  ephemeral      = false
  revoked        = false
}

resource "netbird_network" "private" {
  name        = "hetzner-private"
  description = "Hetzner private network ${var.private_network}"
}

resource "netbird_network_router" "gateway" {
  network_id  = netbird_network.private.id
  peer_groups = [netbird_group.routing_peers.id]
  masquerade  = true
  metric      = 9999
  enabled     = true
}

resource "netbird_group" "resource" {
  for_each = var.resources
  name     = "res-${each.key}"
}

resource "netbird_network_resource" "this" {
  for_each = var.resources

  network_id  = netbird_network.private.id
  name        = each.key
  description = each.value.description
  address     = each.value.address
  groups      = [netbird_group.resource[each.key].id]
  enabled     = true
}

resource "netbird_policy" "this" {
  for_each = var.policies

  name    = each.key
  enabled = true

  rule {
    name          = each.key
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = each.value.protocol
    ports         = each.value.ports
    sources       = [for g in each.value.sources : data.netbird_group.jwt[g].id]
    # A network resource, or the routing peers themselves: traffic to the gateway's own IPs (e.g. its
    # dnsmasq on 10.0.1.2) is delivered locally, not routed – the peer ACL decides, not the resource policy
    destinations = [each.value.resource == null ? netbird_group.routing_peers.id : netbird_group.resource[each.value.resource].id]
  }
}

# Internal names (*.intern.<domain>) through the gateway's dnsmasq – reachable via the dns resource
resource "netbird_nameserver_group" "internal" {
  name        = "intern"
  description = "Internal zone via the gateway's dnsmasq"
  nameservers = [{ ip = var.internal_dns_ip, ns_type = "udp", port = 53 }]
  domains     = [var.internal_domain]
  groups      = [for g in distinct(concat(var.user_groups, var.admin_groups)) : data.netbird_group.jwt[g].id]
  primary     = false
  enabled     = true

  search_domains_enabled = false
}
