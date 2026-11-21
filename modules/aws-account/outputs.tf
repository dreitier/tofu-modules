output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "tofu_role_arn" {
  value = one(aws_iam_role.tofu[*].arn)
}
