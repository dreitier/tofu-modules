# Account-wide settings of the AWS account (management account of a single-account organization):
# the organization itself, cost budgets, the IAM users with admin rights (break-glass) and the role OpenTofu
# runs as. Everything but the role predates basement and is imported. People log in via IAM Identity Center
# (aws/identity-center), the admin users here are the fallback when Keycloak or Identity Center is unavailable. Their access keys
# are not managed (they would end up in the state).

data "aws_caller_identity" "current" {}

# --- Organization -------------------------------------------------------------------------------------

import {
  for_each = var.organization_id == null ? {} : { this = var.organization_id }
  to       = aws_organizations_organization.this
  id       = each.value
}

resource "aws_organizations_organization" "this" {
  feature_set                   = "ALL"
  aws_service_access_principals = var.organization_service_access_principals
  enabled_policy_types          = var.organization_policy_types

  lifecycle {
    prevent_destroy = true
  }
}

# --- Budgets ------------------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.budgets : k => v if v.import }
  to       = aws_budgets_budget.this[each.key]
  id       = "${data.aws_caller_identity.current.account_id}:${each.key}"
}

resource "aws_budgets_budget" "this" {
  for_each = var.budgets

  name              = each.key
  budget_type       = "COST"
  limit_amount      = each.value.limit_amount
  limit_unit        = each.value.limit_unit
  time_unit         = "MONTHLY"
  time_period_start = each.value.time_period_start
  time_period_end   = each.value.time_period_end

  cost_types {
    include_credit = each.value.include_credit
    include_refund = each.value.include_refund
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold_percent
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value.type
      subscriber_email_addresses = notification.value.emails
    }
  }
}

# --- Admin IAM users ----------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.admin_users : k => v if v.import }
  to       = aws_iam_user.admin[each.key]
  id       = each.key
}

resource "aws_iam_user" "admin" {
  for_each = var.admin_users

  name = each.key
  tags = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = { for k, v in var.admin_users : k => v if v.import }
  to       = aws_iam_user_policy_attachment.admin[each.key]
  id       = "${each.key}/arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy_attachment" "admin" {
  for_each = var.admin_users

  user       = aws_iam_user.admin[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- OpenTofu role --------------------------------------------------------------------------------------

# Role that OpenTofu runs as (profile basement: role_arn + source_profile) – not tied to a person. Assumed
# from the SSO roles of the trusted permission sets (role chaining, max 1 h, the SDK refreshes via the SSO
# session) or, break-glass, from the admin IAM users. AdministratorAccess without the billing deny of the
# SSO permission set, so budgets etc. stay manageable. docs/aws-sso.md
data "aws_iam_policy_document" "tofu_trust" {
  count = var.tofu_role == null ? 0 : 1

  statement {
    actions = ["sts:AssumeRole", "sts:SetSourceIdentity", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = concat(
        [for ps in var.tofu_role.trusted_permission_sets :
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_${ps}_*"
        ],
        [for u in keys(var.admin_users) : aws_iam_user.admin[u].arn],
      )
    }
  }
}

resource "aws_iam_role" "tofu" {
  count = var.tofu_role == null ? 0 : 1

  name                 = var.tofu_role.name
  description          = "OpenTofu (basement), assumed from IAM Identity Center admins or break-glass users"
  assume_role_policy   = data.aws_iam_policy_document.tofu_trust[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "tofu" {
  count = var.tofu_role == null ? 0 : 1

  role       = aws_iam_role.tofu[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
