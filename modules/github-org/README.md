# github-org

GitHub organization: settings, teams, team membership, Actions variables. Organization members are NOT
managed here: with GitHub Enterprise Cloud via SAML SSO + team sync (Entra groups); without it,
invitations stay manual and team membership comes from var.team_members.
The organization exists already → import (tg-env procedure: import blocks, plan shows 0 to destroy).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_actions_variables"></a> [actions\_variables](#input\_actions\_variables) | Organization-wide Actions variables (name → value), visible to all repositories | `map(string)` | `{}` | no |
| <a name="input_entra_group_ids"></a> [entra\_group\_ids](#input\_entra\_group\_ids) | Object IDs of the Entra groups by name (output group\_ids of entra/groups) | `map(string)` | `{}` | no |
| <a name="input_github_admin_app"></a> [github\_admin\_app](#input\_github\_admin\_app) | GitHub App used by OpenTofu (key: github\_admin\_app\_private\_key in SOPS); null = github\_token | <pre>object({<br/>    app_id          = string<br/>    installation_id = string<br/>  })</pre> | `null` | no |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | Organization login (config/globals/github.tfvars) | `string` | n/a | yes |
| <a name="input_import_actions_variables"></a> [import\_actions\_variables](#input\_import\_actions\_variables) | Names in actions\_variables that already exist on GitHub (set by hand) → imported instead of created | `set(string)` | `[]` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | n/a | <pre>object({<br/>    billing_email                   = string<br/>    name                            = optional(string)<br/>    description                     = optional(string)<br/>    blog                            = optional(string)<br/>    location                        = optional(string)<br/>    email                           = optional(string) # public profile e-mail<br/>    twitter_username                = optional(string)<br/>    default_repository_permission   = optional(string, "read")<br/>    members_can_create_repositories = optional(bool, false)<br/>    web_commit_signoff_required     = optional(bool, false)<br/>    # Dependabot alerts + security updates + dependency graph for new repositories<br/>    security_defaults_for_new_repositories = optional(bool, true)<br/>  })</pre> | n/a | yes |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml) | `string` | n/a | yes |
| <a name="input_team_members"></a> [team\_members](#input\_team\_members) | GitHub logins per team (without team sync); they must be organization members already | <pre>map(object({<br/>    members     = optional(list(string), [])<br/>    maintainers = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_team_sync"></a> [team\_sync](#input\_team\_sync) | Map teams to Entra groups (GitHub Enterprise Cloud + team sync only) | `bool` | `false` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | n/a | <pre>map(object({<br/>    description = optional(string, "")<br/>    parent      = optional(string)<br/>    entra_group = optional(string) # Entra group name (entra/groups) for team sync<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_team_ids"></a> [team\_ids](#output\_team\_ids) | Team IDs by name (repository access in github/repos) |
| <a name="output_team_slugs"></a> [team\_slugs](#output\_team\_slugs) | n/a |
<!-- END_TF_DOCS -->
