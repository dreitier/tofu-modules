output "group_ids" {
  value       = { for k, g in azuread_group.this : k => g.object_id }
  description = "Object IDs of the security groups by name"
}

output "m365_group_ids" {
  value       = { for k, g in azuread_group.m365 : k => g.object_id }
  description = "Object IDs of the Microsoft 365 groups by name"
}

output "m365_group_mails" {
  value       = { for k, g in azuread_group.m365 : k => g.mail }
  description = "Primary addresses of the Microsoft 365 groups by name"
}

output "users" {
  value = {
    for upn, u in data.azuread_user.members : upn => {
      display_name = u.display_name
      given_name   = u.given_name
      surname      = u.surname
      mail         = u.mail
    }
  }
  description = "Members of the managed groups by UPN: display name, given name, surname, mail"
}
