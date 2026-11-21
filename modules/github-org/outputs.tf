output "team_ids" {
  value       = { for k, t in local.teams : k => t.id }
  description = "Team IDs by name (repository access in github/repos)"
}

output "team_slugs" {
  value = { for k, t in local.teams : k => t.slug }
}
