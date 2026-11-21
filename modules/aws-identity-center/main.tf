# IAM Identity Center: Identity Store users/groups, permission sets and their assignments to the AWS account.
# Login: SAML via Keycloak (client "aws" in config/keycloak). Provisioning is manual – no SCIM: users,
# groups and memberships are managed here, from config/entra/groups.tfvars (stage aws/identity-center).
# The SAML NameID (format emailAddress, the user's mail) must equal the Identity Store UserName (= UPN).
# docs/aws-sso.md

data "aws_ssoadmin_instances" "this" {}

data "aws_caller_identity" "current" {}

locals {
  instance_arn      = one(data.aws_ssoadmin_instances.this.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  account_id        = data.aws_caller_identity.current.account_id
}

# --- Identity Store: users, groups, memberships -------------------------------------------------------

# Existing users (formerly provisioned by Entra SCIM) are imported by UserName
data "aws_identitystore_user" "import" {
  for_each = { for k, v in var.users : k => v if v.import }

  identity_store_id = local.identity_store_id
  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

import {
  for_each = { for k, v in var.users : k => v if v.import }
  to       = aws_identitystore_user.this[each.key]
  id       = "${local.identity_store_id}/${data.aws_identitystore_user.import[each.key].user_id}"
}

resource "aws_identitystore_user" "this" {
  for_each = var.users

  identity_store_id = local.identity_store_id
  user_name         = each.key
  display_name      = each.value.display_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
    type    = "work"
  }
}

data "aws_identitystore_group" "import" {
  for_each = { for k, v in var.groups : k => v if v.import }

  identity_store_id = local.identity_store_id
  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }
}

import {
  for_each = { for k, v in var.groups : k => v if v.import }
  to       = aws_identitystore_group.this[each.key]
  id       = "${local.identity_store_id}/${data.aws_identitystore_group.import[each.key].group_id}"
}

resource "aws_identitystore_group" "this" {
  for_each = var.groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}

# Members added outside Tofu are not removed (no authoritative membership resource in the provider)
locals {
  memberships = merge([
    for g, v in var.groups : { for upn in v.members : "${g}/${upn}" => { group = g, user = upn } }
  ]...)
}

resource "aws_identitystore_group_membership" "this" {
  for_each = local.memberships

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = aws_identitystore_user.this[each.value.user].user_id
}

# Every member of a group must also be in the login group – Keycloak lets only that group into the client
check "login_group" {
  assert {
    condition = var.login_group == null || alltrue([
      for m in values(local.memberships) : contains(var.groups[var.login_group].members, m.user)
    ])
    error_message = "Members of ${jsonencode(keys(var.groups))} must also be in ${coalesce(var.login_group, "-")}, otherwise Keycloak denies their login."
  }
}

# --- Permission sets ----------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.permission_sets : k => v if v.import_arn != null }
  to       = aws_ssoadmin_permission_set.this[each.key]
  id       = "${each.value.import_arn},${local.instance_arn}"
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  instance_arn     = local.instance_arn
  name             = each.key
  description      = each.value.description
  session_duration = each.value.session_duration
}

locals {
  managed_policies = merge([
    for ps, p in var.permission_sets : {
      for arn in p.managed_policy_arns : "${ps}/${arn}" => { ps = ps, arn = arn, import = p.import_arn != null }
    }
  ]...)
}

import {
  for_each = { for k, v in local.managed_policies : k => v if v.import }
  to       = aws_ssoadmin_managed_policy_attachment.this[each.key]
  id       = "${each.value.arn},${var.permission_sets[each.value.ps].import_arn},${local.instance_arn}"
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.managed_policies

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps].arn
  managed_policy_arn = each.value.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = { for k, v in var.permission_sets : k => v if v.inline_policy != null }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value.inline_policy
}

# --- Assignments to this account (principals managed above) -------------------------------------------

locals {
  assignments = {
    for a in var.assignments : "${a.permission_set}/${a.principal_type}/${a.principal}" => merge(a, {
      principal_id = (a.principal_type == "GROUP"
        ? aws_identitystore_group.this[a.principal].group_id
        : aws_identitystore_user.this[a.principal].user_id
      )
    })
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
  target_id          = local.account_id
  target_type        = "AWS_ACCOUNT"

  # Policies must be attached before the assignment provisions the role
  depends_on = [aws_ssoadmin_managed_policy_attachment.this, aws_ssoadmin_permission_set_inline_policy.this]
}
