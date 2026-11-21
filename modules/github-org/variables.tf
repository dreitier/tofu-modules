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

variable "settings" {
  type = object({
    billing_email                   = string
    name                            = optional(string)
    description                     = optional(string)
    blog                            = optional(string)
    location                        = optional(string)
    email                           = optional(string) # public profile e-mail
    twitter_username                = optional(string)
    default_repository_permission   = optional(string, "read")
    members_can_create_repositories = optional(bool, false)
    web_commit_signoff_required     = optional(bool, false)
    # Dependabot alerts + security updates + dependency graph for new repositories
    security_defaults_for_new_repositories = optional(bool, true)
  })
}

variable "teams" {
  type = map(object({
    description = optional(string, "")
    parent      = optional(string)
    entra_group = optional(string) # Entra group name (entra/groups) for team sync
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.teams : v.parent == null || try(var.teams[v.parent].parent == null, false)
    ])
    error_message = "A team's parent must be a top-level team defined in var.teams (one level of nesting)."
  }
}

variable "team_members" {
  type = map(object({
    members     = optional(list(string), [])
    maintainers = optional(list(string), [])
  }))
  default     = {}
  description = "GitHub logins per team (without team sync); they must be organization members already"

  validation {
    condition     = length(setsubtract(keys(var.team_members), keys(var.teams))) == 0
    error_message = "team_members contains a team that is not defined in var.teams."
  }

  validation {
    condition     = alltrue([for k, v in var.team_members : length(setintersection(v.members, v.maintainers)) == 0])
    error_message = "A login must be listed either in members or in maintainers of a team, not in both."
  }

  validation {
    condition     = !(var.team_sync && length(var.team_members) > 0)
    error_message = "Team members are managed by team sync when team_sync = true – leave team_members empty."
  }
}

variable "team_sync" {
  type        = bool
  default     = false
  description = "Map teams to Entra groups (GitHub Enterprise Cloud + team sync only)"
}

variable "entra_group_ids" {
  type        = map(string)
  default     = {}
  description = "Object IDs of the Entra groups by name (output group_ids of entra/groups)"
}

variable "actions_variables" {
  type        = map(string)
  default     = {}
  description = "Organization-wide Actions variables (name → value), visible to all repositories"
}

variable "import_actions_variables" {
  type        = set(string)
  default     = []
  description = "Names in actions_variables that already exist on GitHub (set by hand) → imported instead of created"

  validation {
    condition     = length(setsubtract(var.import_actions_variables, keys(var.actions_variables))) == 0
    error_message = "import_actions_variables may only contain names from actions_variables."
  }
}
