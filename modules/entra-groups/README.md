# entra-groups

Entra ID security groups = roles across all systems (single source of truth). Their object IDs flow
to Keycloak (group mapper), Entra app assignments, … via outputs and dependency blocks; AWS Identity
Center gets groups and members from the same tfvars plus the member attributes (output users).
Existing groups are imported (object_id set). Membership is managed here for groups with a `members`
list (authoritative: members added in the portal are removed by the next apply);
members = null leaves membership to Entra, dynamic groups get their rule instead.
Microsoft 365 (Unified) groups: m365.tf. Mail distribution lists can't be managed through Microsoft Graph
(Exchange only) – scripts/exchange/.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | n/a | `string` | n/a | yes |
| <a name="input_groups"></a> [groups](#input\_groups) | Security groups by display name (config/entra/groups.tfvars) | <pre>map(object({<br/>    object_id   = optional(string) # existing group → import<br/>    description = optional(string)<br/>    # user principal names; authoritative when set, null = membership not managed<br/>    members                 = optional(list(string))<br/>    dynamic_membership_rule = optional(string) # dynamic group (members must be null)<br/>  }))</pre> | n/a | yes |
| <a name="input_m365_groups"></a> [m365\_groups](#input\_m365\_groups) | Microsoft 365 (Unified) groups by display name (config/entra/m365-groups.tfvars) | <pre>map(object({<br/>    object_id   = optional(string) # existing group → import<br/>    description = optional(string)<br/>    # Alias of the group (Graph mailNickname = Exchange Alias), required by the provider. Must match the existing<br/>    # value exactly: a change recreates the group (prevent_destroy stops that).<br/>    # az ad group show --group <object_id> --query mailNickname -o tsv<br/>    mail_nickname = string<br/>    visibility    = optional(string) # Private | Public; null = keep<br/>    # ["Team"] for groups with a Microsoft Teams team – set at creation only, a difference recreates the group<br/>    provisioning_options = optional(list(string))<br/>    # Group behaviors (HideGroupInOutlook, WelcomeEmailDisabled, …) – set at creation only, a difference<br/>    # recreates the group<br/>    behaviors = optional(list(string))<br/>    # Some older groups are security-enabled too (usable in access policies); keep what Entra has<br/>    security_enabled = optional(bool, false)<br/>    # user principal names; authoritative when set, null = membership not managed<br/>    members = optional(list(string))<br/>    # Members added later get group mail in their inbox (subscriber). Existing members are not subscribed by<br/>    # this – scripts/exchange/m365-group-subscribers.ps1. The following need a delegated login (az login).<br/>    auto_subscribe_new_members = optional(bool)<br/>    external_senders_allowed   = optional(bool)<br/>    hide_from_address_lists    = optional(bool)<br/>    hide_from_outlook_clients  = optional(bool)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_group_ids"></a> [group\_ids](#output\_group\_ids) | Object IDs of the security groups by name |
| <a name="output_m365_group_ids"></a> [m365\_group\_ids](#output\_m365\_group\_ids) | Object IDs of the Microsoft 365 groups by name |
| <a name="output_m365_group_mails"></a> [m365\_group\_mails](#output\_m365\_group\_mails) | Primary addresses of the Microsoft 365 groups by name |
| <a name="output_users"></a> [users](#output\_users) | Members of the managed groups by UPN: display name, given name, surname, mail |
<!-- END_TF_DOCS -->
