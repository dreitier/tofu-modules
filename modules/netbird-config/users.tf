# NetBird doesn't derive roles from JWT groups (docs/netbird.md) → roles of the infrastruktur_SG members here.
# The users come from the Keycloak login; they are looked up and imported, never invited.
data "netbird_user" "managed" {
  for_each = var.user_roles
  email    = each.key
}

import {
  for_each = var.user_roles
  to       = netbird_user.managed[each.key]
  id       = data.netbird_user.managed[each.key].id
}

resource "netbird_user" "managed" {
  for_each = var.user_roles

  is_service_user = false
  email           = each.key
  role            = each.value
  is_blocked      = false

  lifecycle {
    # auto_groups belong to the JWT group sync, name to the IdP – never overwrite them
    ignore_changes  = [auto_groups, name, is_blocked]
    prevent_destroy = true
  }
}
