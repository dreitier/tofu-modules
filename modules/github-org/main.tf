# GitHub organization: settings, teams, team membership, Actions variables. Organization members are NOT
# managed here: with GitHub Enterprise Cloud via SAML SSO + team sync (Entra groups); without it,
# invitations stay manual and team membership comes from var.team_members.
# The organization exists already → import (tg-env procedure: import blocks, plan shows 0 to destroy).

resource "github_organization_settings" "this" {
  billing_email = var.settings.billing_email
  name          = var.settings.name
  description   = var.settings.description
  blog          = var.settings.blog
  location      = var.settings.location
  email         = var.settings.email

  twitter_username = var.settings.twitter_username

  default_repository_permission           = var.settings.default_repository_permission
  members_can_create_repositories         = var.settings.members_can_create_repositories
  members_can_create_public_repositories  = var.settings.members_can_create_repositories
  members_can_create_private_repositories = var.settings.members_can_create_repositories
  members_can_fork_private_repositories   = false
  web_commit_signoff_required             = var.settings.web_commit_signoff_required

  dependabot_alerts_enabled_for_new_repositories           = var.settings.security_defaults_for_new_repositories
  dependabot_security_updates_enabled_for_new_repositories = var.settings.security_defaults_for_new_repositories
  dependency_graph_enabled_for_new_repositories            = var.settings.security_defaults_for_new_repositories

  lifecycle {
    # Destroying this resource resets the organization's settings
    prevent_destroy = true
  }
}

# Teams are split into two resources: a for_each resource must not reference its own instances
# (dependency cycle), so child teams live in github_team.child and point to top-level teams. One level
# of nesting only (validated in variables.tf).
resource "github_team" "this" {
  for_each = { for k, v in var.teams : k => v if v.parent == null }

  name        = each.key
  description = each.value.description
  privacy     = "closed"

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team" "child" {
  for_each = { for k, v in var.teams : k => v if v.parent != null }

  name           = each.key
  description    = each.value.description
  privacy        = "closed"
  parent_team_id = github_team.this[each.value.parent].id

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  # Only the attributes used here and in the outputs – the whole resource objects would carry the deprecated
  # create_default_maintainer along ("Value derived from a deprecated source" on every plan)
  teams = { for k, t in merge(github_team.this, github_team.child) : k => { id = t.id, slug = t.slug } }
}

# Team membership from Entra groups (needs GitHub Enterprise Cloud with team sync enabled)
resource "github_team_sync_group_mapping" "this" {
  for_each = { for k, v in var.teams : k => v if v.entra_group != null && var.team_sync }

  team_slug = local.teams[each.key].slug

  group {
    group_id          = var.entra_group_ids[each.value.entra_group]
    group_name        = each.value.entra_group
    group_description = each.value.description
  }
}

# Team membership without team sync (no GitHub Enterprise Cloud): logins from var.team_members. Only team
# membership is managed – organization membership (invitations, removal) stays manual, so a wrong list
# can never remove anybody from the organization.
resource "github_team_membership" "this" {
  for_each = var.team_sync ? {} : merge([
    for team, t in var.team_members : merge(
      { for u in t.members : "${team}/${u}" => { team = team, username = u, role = "member" } },
      { for u in t.maintainers : "${team}/${u}" => { team = team, username = u, role = "maintainer" } },
    )
  ]...)

  team_id  = local.teams[each.value.team].id
  username = each.value.username
  role     = each.value.role
}

# Non-secret organization-wide Actions variables (e.g. RELEASE_APP_CLIENT_ID of the release bot).
# Variables created by hand are imported (var.import_actions_variables); creating them again fails (409).
import {
  for_each = var.import_actions_variables
  to       = github_actions_organization_variable.this[each.key]
  id       = each.key
}

resource "github_actions_organization_variable" "this" {
  for_each = var.actions_variables

  variable_name = each.key
  value         = each.value
  visibility    = "all"
}

# Organization secrets (e.g. RELEASE_APP_PRIVATE_KEY) are deliberately not managed here: the provider
# keeps plaintext_value in the state. Set them with `gh secret set --org`, or use encrypted_value
# (pre-encrypted with the org's public key) if they must be in code.
