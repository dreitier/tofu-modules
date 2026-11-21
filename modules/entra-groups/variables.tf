variable "entra_tenant_id" {
  type = string
}

variable "groups" {
  type = map(object({
    object_id   = optional(string) # existing group → import
    description = optional(string)
    # user principal names; authoritative when set, null = membership not managed
    members                 = optional(list(string))
    dynamic_membership_rule = optional(string) # dynamic group (members must be null)
  }))
  description = "Security groups by display name (config/entra/groups.tfvars)"

  validation {
    condition     = alltrue([for g in values(var.groups) : g.members == null || g.dynamic_membership_rule == null])
    error_message = "A dynamic group can't have a members list."
  }
}

variable "m365_groups" {
  type = map(object({
    object_id   = optional(string) # existing group → import
    description = optional(string)
    # Alias of the group (Graph mailNickname = Exchange Alias), required by the provider. Must match the existing
    # value exactly: a change recreates the group (prevent_destroy stops that).
    # az ad group show --group <object_id> --query mailNickname -o tsv
    mail_nickname = string
    visibility    = optional(string) # Private | Public; null = keep
    # ["Team"] for groups with a Microsoft Teams team – set at creation only, a difference recreates the group
    provisioning_options = optional(list(string))
    # Group behaviors (HideGroupInOutlook, WelcomeEmailDisabled, …) – set at creation only, a difference
    # recreates the group
    behaviors = optional(list(string))
    # Some older groups are security-enabled too (usable in access policies); keep what Entra has
    security_enabled = optional(bool, false)
    # user principal names; authoritative when set, null = membership not managed
    members = optional(list(string))
    # Members added later get group mail in their inbox (subscriber). Existing members are not subscribed by
    # this – scripts/exchange/m365-group-subscribers.ps1. The following need a delegated login (az login).
    auto_subscribe_new_members = optional(bool)
    external_senders_allowed   = optional(bool)
    hide_from_address_lists    = optional(bool)
    hide_from_outlook_clients  = optional(bool)
  }))
  default     = {}
  description = "Microsoft 365 (Unified) groups by display name (config/entra/m365-groups.tfvars)"

  validation {
    condition     = alltrue([for g in values(var.m365_groups) : g.visibility == null || contains(["Private", "Public"], coalesce(g.visibility, "-"))])
    error_message = "visibility must be Private or Public."
  }
}
