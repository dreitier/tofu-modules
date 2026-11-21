# Repositories of the GitHub organization: settings, team access, the default-branch ruleset.
# Contents, branches and workflows stay with git. Defaults follow the conventions of backmon/helm-charts:
# squash merge only (commit message = PR title + description; merge commits opt-in per repository with
# allow_merge_commit), auto-merge allowed (opt-out per repository),
# head branches deleted after merge, ruleset "main" on the default branch, the release bot (GitHub App)
# may bypass it to push releases.
# Existing repositories are imported (import = true); deleting an entry archives the repository
# (archive_on_destroy), prevent_destroy blocks replacements – this project's own repository is one of them.

import {
  for_each = { for k, v in var.repositories : k => v if v.import }
  to       = github_repository.this[each.key]
  id       = each.key
}

resource "github_repository" "this" {
  for_each = var.repositories

  name         = each.key
  description  = each.value.description
  homepage_url = each.value.homepage_url
  visibility   = each.value.visibility
  topics       = each.value.topics
  archived     = each.value.archived

  has_issues      = each.value.has_issues
  has_projects    = each.value.has_projects
  has_wiki        = each.value.has_wiki
  has_discussions = each.value.has_discussions

  allow_merge_commit          = each.value.allow_merge_commit
  merge_commit_title          = each.value.allow_merge_commit ? "PR_TITLE" : null
  merge_commit_message        = each.value.allow_merge_commit ? "PR_BODY" : null
  allow_rebase_merge          = false
  allow_squash_merge          = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  allow_auto_merge            = each.value.allow_auto_merge
  allow_update_branch         = true
  delete_branch_on_merge      = true

  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

# Repositories that are only imported, never changed: OpenTofu knows them (prevent_destroy, visible in the
# state and in outputs) but ignores all their settings. No team access, ruleset or alerts are managed. To
# manage one fully later, move it to var.repositories with a moved block
# (github_repository.import_only["x"] → github_repository.this["x"]).
import {
  for_each = var.import_only_repositories
  to       = github_repository.import_only[each.key]
  id       = each.key
}

resource "github_repository" "import_only" {
  for_each = var.import_only_repositories

  name = each.key

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# Dependabot alerts (replaces the deprecated vulnerability_alerts attribute of github_repository)
resource "github_repository_vulnerability_alerts" "this" {
  for_each = { for k, v in var.repositories : k => v if !v.archived }

  repository = github_repository.this[each.key].name
  enabled    = each.value.vulnerability_alerts
}

# Dependabot security updates: PRs that fix open Dependabot alerts (version updates come from
# .github/dependabot.yml in the repository itself)
resource "github_repository_dependabot_security_updates" "this" {
  for_each = { for k, v in var.repositories : k => v if !v.archived && v.dependabot_security_updates }

  repository = github_repository.this[each.key].name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.this]
}

# Default GITHUB_TOKEN permissions of the workflows (workflows raise them per job with `permissions:`)
resource "github_workflow_repository_permissions" "this" {
  for_each = { for k, v in var.repositories : k => v if !v.archived && v.workflow_permissions != null }

  repository                       = github_repository.this[each.key].name
  default_workflow_permissions     = each.value.workflow_permissions.default
  can_approve_pull_request_reviews = each.value.workflow_permissions.can_approve_pull_requests
}

# Archived repositories are read-only → no team access changes
resource "github_team_repository" "this" {
  for_each = merge([
    for repo, r in var.repositories : r.archived ? {} : {
      for team, permission in r.teams : "${repo}/${team}" => { repo = repo, team = team, permission = permission }
    }
  ]...)

  repository = github_repository.this[each.value.repo].name
  team_id    = var.team_ids[each.value.team]
  permission = each.value.permission
}

locals {
  # Actor IDs of the built-in repository roles in ruleset bypass lists
  repository_role_ids = { maintain = 2, write = 4, admin = 5 }
}

# Ruleset "main" on the default branch. Existing rulesets are imported via ruleset.import_id
# (gh api repos/dreitier/<repo>/rulesets), otherwise a second ruleset named "main" is created.
import {
  for_each = { for k, v in var.repositories : k => v if v.ruleset != null && try(v.ruleset.import_id, null) != null }
  to       = github_repository_ruleset.main[each.key]
  id       = "${each.key}:${each.value.ruleset.import_id}"
}

resource "github_repository_ruleset" "main" {
  for_each = { for k, v in var.repositories : k => v if v.ruleset != null && !v.archived }

  repository  = github_repository.this[each.key].name
  name        = "main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # bypass_actors is an ordered list in the provider, but GitHub returns the actors in its own order
  # (OrganizationAdmin before Integration) – keep the blocks in that order, otherwise every plan swaps them.

  # Organization admins as break-glass. The API returns no actor ID for OrganizationAdmin (state: 0) –
  # 0 instead of 1 avoids a permanent "0 -> 1" diff.
  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }

  # Release bot: pushes CHANGELOG/tags (semantic-release)
  dynamic "bypass_actors" {
    for_each = var.release_app_id == null || !each.value.ruleset.release_bot_bypass ? [] : [var.release_app_id]
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

  # Repository roles that may push directly (e.g. maintain for basement). Actor IDs of the built-in roles.
  dynamic "bypass_actors" {
    for_each = each.value.ruleset.bypass_repository_roles
    content {
      actor_id    = local.repository_role_ids[bypass_actors.value]
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    pull_request {
      required_approving_review_count   = each.value.ruleset.required_approvals
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = false
      required_review_thread_resolution = each.value.ruleset.required_review_thread_resolution
      allowed_merge_methods             = concat(["squash"], each.value.allow_merge_commit ? ["merge"] : [])
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.ruleset.required_checks) == 0 ? [] : [each.value.ruleset.required_checks]
      content {
        strict_required_status_checks_policy = each.value.ruleset.strict_required_checks

        dynamic "required_check" {
          for_each = required_status_checks.value
          content {
            context        = required_check.key
            integration_id = required_check.value
          }
        }
      }
    }
  }
}
