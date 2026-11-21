# github-repos

Repositories of the GitHub organization: settings, team access, the default-branch ruleset.
Contents, branches and workflows stay with git. Defaults follow the conventions of backmon/helm-charts:
squash merge only (commit message = PR title + description; merge commits opt-in per repository with
allow_merge_commit), auto-merge allowed (opt-out per repository),
head branches deleted after merge, ruleset "main" on the default branch, the release bot (GitHub App)
may bypass it to push releases.
Existing repositories are imported (import = true); deleting an entry archives the repository
(archive_on_destroy), prevent_destroy blocks replacements – this project's own repository is one of them.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_github_admin_app"></a> [github\_admin\_app](#input\_github\_admin\_app) | GitHub App used by OpenTofu (key: github\_admin\_app\_private\_key in SOPS); null = github\_token | <pre>object({<br/>    app_id          = string<br/>    installation_id = string<br/>  })</pre> | `null` | no |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | Organization login (config/globals/github.tfvars) | `string` | n/a | yes |
| <a name="input_import_only_repositories"></a> [import\_only\_repositories](#input\_import\_only\_repositories) | Existing repositories that are imported but never changed (all settings ignored) | `set(string)` | `[]` | no |
| <a name="input_release_app_id"></a> [release\_app\_id](#input\_release\_app\_id) | App ID of the release bot (dreitier-release-bot), bypass actor of the main rulesets | `number` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repositories of the organization, key = name | <pre>map(object({<br/>    import           = optional(bool, true) # existing repository → import instead of create<br/>    description      = optional(string, "")<br/>    homepage_url     = optional(string)<br/>    visibility       = optional(string, "public")<br/>    topics           = optional(list(string), [])<br/>    archived         = optional(bool, false)<br/>    has_issues       = optional(bool, true)<br/>    has_projects     = optional(bool, false)<br/>    has_wiki         = optional(bool, false)<br/>    has_discussions  = optional(bool, false)<br/>    allow_auto_merge = optional(bool, true) # "Allow auto-merge" – on by default, opt-out with false<br/>    # Merge commits in addition to squash – only for repositories with a develop → main release flow<br/>    # (release PR merged with a merge commit, main merged back into develop); default squash only<br/>    allow_merge_commit   = optional(bool, false)<br/>    vulnerability_alerts = optional(bool, true)<br/>    # Dependabot security updates (fix PRs for alerts) – opt-in, needs vulnerability_alerts<br/>    dependabot_security_updates = optional(bool, false)<br/>    teams                       = optional(map(string), {}) # team name → pull | triage | push | maintain | admin<br/>    # Default permissions of the workflows' GITHUB_TOKEN – opt-in (omitted = not managed)<br/>    workflow_permissions = optional(object({<br/>      default                   = optional(string, "read") # read | write<br/>      can_approve_pull_requests = optional(bool, false)<br/>    }))<br/><br/>    # Ruleset "main" – opt-in: omitted = no ruleset (a null would be replaced by an object default).<br/>    # import_id: ID of an existing "main" ruleset (imported instead of created)<br/>    ruleset = optional(object({<br/>      import_id                         = optional(number)<br/>      required_approvals                = optional(number, 0)<br/>      required_review_thread_resolution = optional(bool, false)<br/>      # check name (context) → app ID that must report it (15368 = GitHub Actions); null = any source<br/>      required_checks = optional(map(number), {})<br/>      # "Require branches to be up to date before merging" for the required checks<br/>      strict_required_checks = optional(bool, false)<br/>      release_bot_bypass     = optional(bool, true)<br/>      # repository roles that may bypass the ruleset (push directly): maintain | write | admin<br/>      bypass_repository_roles = optional(list(string), [])<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_team_ids"></a> [team\_ids](#input\_team\_ids) | Team IDs by name (output team\_ids of github/org) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | n/a |
<!-- END_TF_DOCS -->
