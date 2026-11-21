# Entra ID security groups = roles across all systems (single source of truth). Their object IDs flow
# to Keycloak (group mapper), Entra app assignments, … via outputs and dependency blocks; AWS Identity
# Center gets groups and members from the same tfvars plus the member attributes (output users).
# Existing groups are imported (object_id set). Membership is managed here for groups with a `members`
# list (authoritative: members added in the portal are removed by the next apply);
# members = null leaves membership to Entra, dynamic groups get their rule instead.
# Microsoft 365 (Unified) groups: m365.tf. Mail distribution lists can't be managed through Microsoft Graph
# (Exchange only) – scripts/exchange/.

import {
  for_each = { for k, v in var.groups : k => v if v.object_id != null }
  to       = azuread_group.this[each.key]
  id       = "/groups/${each.value.object_id}"
}

locals {
  member_upns = sort(distinct(flatten([for g in merge(var.groups, var.m365_groups) : coalesce(g.members, [])])))
}

data "azuread_users" "members" {
  user_principal_names = local.member_upns
}

locals {
  user_ids = zipmap(data.azuread_users.members.user_principal_names, data.azuread_users.members.object_ids)
}

# Name attributes of the members (azuread_users has no given name/surname) – output users, consumed by
# aws/identity-center (Identity Store users)
data "azuread_user" "members" {
  for_each = toset(local.member_upns)

  user_principal_name = each.key
}

resource "azuread_group" "this" {
  for_each = var.groups

  display_name     = each.key
  description      = each.value.description
  security_enabled = true
  types            = each.value.dynamic_membership_rule == null ? null : ["DynamicMembership"]

  members = each.value.members == null ? null : [for upn in each.value.members : local.user_ids[upn]]

  dynamic "dynamic_membership" {
    for_each = each.value.dynamic_membership_rule == null ? [] : [each.value.dynamic_membership_rule]
    content {
      enabled = true
      rule    = dynamic_membership.value
    }
  }

  lifecycle {
    prevent_destroy = true
    # Owners stay as they are in Entra (the creator becomes owner of new groups)
    ignore_changes = [owners]
  }
}
