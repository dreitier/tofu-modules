# Existing app registrations and their enterprise applications (service principals), imported as they
# are: OpenTofu protects them (prevent_destroy) and knows their IDs, but leaves their configuration
# (redirect URIs, SAML settings, app roles, credentials) to the portal – ignore_changes = all. Managed
# here is who may use them: the app role assignments. Target model: groups (*_SG of entra/groups) only;
# direct user assignments are the imported state of 2026-11. To manage an app's configuration fully,
# move it to its own resources (with moved/import blocks) like Keycloak above.
# Client secrets are never created here (they would end up in the state).

import {
  for_each = var.imported_apps
  to       = azuread_application.imported[each.key]
  id       = "/applications/${each.value.application_object_id}"
}

resource "azuread_application" "imported" {
  for_each = var.imported_apps

  display_name = each.value.display_name

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

import {
  for_each = var.imported_apps
  to       = azuread_service_principal.imported[each.key]
  id       = "/servicePrincipals/${each.value.service_principal_object_id}"
}

resource "azuread_service_principal" "imported" {
  for_each = var.imported_apps

  client_id = azuread_application.imported[each.key].client_id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# --- App role assignments -----------------------------------------------------------------------------

locals {
  # "00000000-…" = default access (apps without app roles)
  default_app_role_id = "00000000-0000-0000-0000-000000000000"

  app_assignments = merge([
    for app, a in var.imported_apps : {
      for x in a.assignments : "${app}/${x.principal_type}/${x.principal}/${coalesce(x.app_role_id, local.default_app_role_id)}" => merge(x, {
        app         = app
        app_role_id = coalesce(x.app_role_id, local.default_app_role_id)
      })
    }
  ]...)

  assignment_groups = toset([for x in values(local.app_assignments) : x.principal if x.principal_type == "Group"])
  assignment_users  = sort(distinct([for x in values(local.app_assignments) : x.principal if x.principal_type == "User"]))
}

data "azuread_group" "assignment" {
  for_each = local.assignment_groups

  display_name     = each.key
  security_enabled = true
}

data "azuread_users" "assignment" {
  user_principal_names = local.assignment_users
}

locals {
  assignment_user_ids = zipmap(data.azuread_users.assignment.user_principal_names, data.azuread_users.assignment.object_ids)
}

import {
  for_each = { for k, v in local.app_assignments : k => v if v.import_id != null }
  to       = azuread_app_role_assignment.imported[each.key]
  id       = "/servicePrincipals/${var.imported_apps[each.value.app].service_principal_object_id}/appRoleAssignedTo/${each.value.import_id}"
}

resource "azuread_app_role_assignment" "imported" {
  for_each = local.app_assignments

  resource_object_id  = azuread_service_principal.imported[each.value.app].object_id
  app_role_id         = each.value.app_role_id
  principal_object_id = each.value.principal_type == "Group" ? data.azuread_group.assignment[each.value.principal].object_id : local.assignment_user_ids[each.value.principal]
}
