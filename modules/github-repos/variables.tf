variable "sops_file" {
  type        = string
  description = "SOPS-encrypted secrets file (config/sops-secrets.yaml)"
}

variable "github_owner" {
  type        = string
  description = "Organization login (config/globals/github.tfvars)"
}

variable "github_admin_app" {
  type = object({
    app_id          = string
    installation_id = string
  })
  default     = null
  description = "GitHub App used by OpenTofu (key: github_admin_app_private_key in SOPS); null = github_token"
}

variable "team_ids" {
  type        = map(string)
  default     = {}
  description = "Team IDs by name (output team_ids of github/org)"
}

variable "release_app_id" {
  type        = number
  default     = null
  description = "App ID of the release bot (dreitier-release-bot), bypass actor of the main rulesets"
}

variable "repositories" {
  type = map(object({
    import           = optional(bool, true) # existing repository → import instead of create
    description      = optional(string, "")
    homepage_url     = optional(string)
    visibility       = optional(string, "public")
    topics           = optional(list(string), [])
    archived         = optional(bool, false)
    has_issues       = optional(bool, true)
    has_projects     = optional(bool, false)
    has_wiki         = optional(bool, false)
    has_discussions  = optional(bool, false)
    allow_auto_merge = optional(bool, true) # "Allow auto-merge" – on by default, opt-out with false
    # Merge commits in addition to squash – only for repositories with a develop → main release flow
    # (release PR merged with a merge commit, main merged back into develop); default squash only
    allow_merge_commit   = optional(bool, false)
    vulnerability_alerts = optional(bool, true)
    # Dependabot security updates (fix PRs for alerts) – opt-in, needs vulnerability_alerts
    dependabot_security_updates = optional(bool, false)
    teams                       = optional(map(string), {}) # team name → pull | triage | push | maintain | admin
    # Default permissions of the workflows' GITHUB_TOKEN – opt-in (omitted = not managed)
    workflow_permissions = optional(object({
      default                   = optional(string, "read") # read | write
      can_approve_pull_requests = optional(bool, false)
    }))

    # Ruleset "main" – opt-in: omitted = no ruleset (a null would be replaced by an object default).
    # import_id: ID of an existing "main" ruleset (imported instead of created)
    ruleset = optional(object({
      import_id                         = optional(number)
      required_approvals                = optional(number, 0)
      required_review_thread_resolution = optional(bool, false)
      # check name (context) → app ID that must report it (15368 = GitHub Actions); null = any source
      required_checks = optional(map(number), {})
      # "Require branches to be up to date before merging" for the required checks
      strict_required_checks = optional(bool, false)
      release_bot_bypass     = optional(bool, true)
      # repository roles that may bypass the ruleset (push directly): maintain | write | admin
      bypass_repository_roles = optional(list(string), [])
    }))
  }))
  description = "Repositories of the organization, key = name"

  validation {
    condition     = alltrue([for k, v in var.repositories : !v.dependabot_security_updates || v.vulnerability_alerts])
    error_message = "dependabot_security_updates needs vulnerability_alerts = true."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.repositories : v.ruleset == null ? [] : [
        for r in v.ruleset.bypass_repository_roles : contains(["maintain", "write", "admin"], r)
      ]
    ]))
    error_message = "ruleset.bypass_repository_roles: allowed values are maintain, write, admin."
  }
}

variable "import_only_repositories" {
  type        = set(string)
  default     = []
  description = "Existing repositories that are imported but never changed (all settings ignored)"

  validation {
    condition     = length(setintersection(var.import_only_repositories, keys(var.repositories))) == 0
    error_message = "A repository must be either in repositories or in import_only_repositories, not in both."
  }
}
