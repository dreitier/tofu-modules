# Microsoft 365 (Unified) groups: group mailbox, calendar, Teams/SharePoint. Imported like the security groups.
# Tested 2026-11-16 (sandbox): creation waits ~90 s for the Exchange mailbox, no drift afterwards, members added
# through Graph become subscribers when auto_subscribe_new_members is on. Attributes left null are not managed.

import {
  for_each = { for k, v in var.m365_groups : k => v if v.object_id != null }
  to       = azuread_group.m365[each.key]
  id       = "/groups/${each.value.object_id}"
}

resource "azuread_group" "m365" {
  for_each = var.m365_groups

  display_name     = each.key
  description      = each.value.description
  types            = ["Unified"]
  mail_enabled     = true
  mail_nickname    = each.value.mail_nickname
  security_enabled = each.value.security_enabled
  visibility       = each.value.visibility

  provisioning_options = each.value.provisioning_options
  behaviors            = each.value.behaviors

  auto_subscribe_new_members = each.value.auto_subscribe_new_members
  external_senders_allowed   = each.value.external_senders_allowed
  hide_from_address_lists    = each.value.hide_from_address_lists
  hide_from_outlook_clients  = each.value.hide_from_outlook_clients

  members = each.value.members == null ? null : [for upn in each.value.members : local.user_ids[upn]]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [owners]
  }
}
