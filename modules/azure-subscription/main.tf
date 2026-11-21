# Resources in the Azure subscription that predate basement (imported): resource groups, container
# registry, storage accounts and the RBAC assignments of people/groups. Cloud Shell storage (csb*) and
# Azure-created groups (DefaultResourceGroup-*) are left alone. Service principal credentials and
# storage keys are not managed (they would end up in the state).

locals {
  subscription_scope = "/subscriptions/${var.azure_subscription_id}"
}

import {
  for_each = { for k, v in var.resource_groups : k => v if v.import }
  to       = azurerm_resource_group.this[each.key]
  id       = "${local.subscription_scope}/resourceGroups/${each.key}"
}

resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.key
  location = each.value.location
  tags     = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = { for k, v in var.container_registries : k => v if v.import }
  to       = azurerm_container_registry.this[each.key]
  id       = "${local.subscription_scope}/resourceGroups/${each.value.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${each.key}"
}

resource "azurerm_container_registry" "this" {
  for_each = var.container_registries

  name                = each.key
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  admin_enabled       = each.value.admin_enabled
  tags                = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = { for k, v in var.storage_accounts : k => v if v.import }
  to       = azurerm_storage_account.this[each.key]
  id       = "${local.subscription_scope}/resourceGroups/${each.value.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${each.key}"
}

resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                             = each.key
  resource_group_name              = each.value.resource_group_name
  location                         = each.value.location
  account_kind                     = "StorageV2"
  account_tier                     = each.value.account_tier
  account_replication_type         = each.value.account_replication_type
  access_tier                      = each.value.access_tier
  allow_nested_items_to_be_public  = each.value.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = each.value.cross_tenant_replication
  shared_access_key_enabled        = each.value.shared_access_key_enabled
  min_tls_version                  = each.value.min_tls_version
  https_traffic_only_enabled       = true
  public_network_access            = each.value.public_network_access
  tags                             = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

# --- RBAC -----------------------------------------------------------------------------------------------

data "azuread_users" "rbac" {
  user_principal_names = sort(distinct([for a in var.role_assignments : a.principal if a.principal_type == "User"]))
}

data "azuread_group" "rbac" {
  for_each = toset([for a in var.role_assignments : a.principal if a.principal_type == "Group"])

  display_name     = each.key
  security_enabled = true
}

locals {
  rbac_user_ids = zipmap(data.azuread_users.rbac.user_principal_names, data.azuread_users.rbac.object_ids)

  role_assignments = {
    for a in var.role_assignments : "${a.scope}/${a.role}/${a.principal_type}/${a.principal}" => merge(a, {
      full_scope   = a.scope == "" ? local.subscription_scope : "${local.subscription_scope}/${a.scope}"
      principal_id = a.principal_type == "Group" ? data.azuread_group.rbac[a.principal].object_id : local.rbac_user_ids[a.principal]
    })
  }
}

import {
  for_each = { for k, v in local.role_assignments : k => v if v.import_id != null }
  to       = azurerm_role_assignment.this[each.key]
  id       = each.value.import_id
}

resource "azurerm_role_assignment" "this" {
  for_each = local.role_assignments

  scope                = each.value.full_scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
  description          = each.value.description
}
