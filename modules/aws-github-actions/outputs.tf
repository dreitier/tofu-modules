output "role_arns" {
  value       = { for k, r in aws_iam_role.this : k => r.arn }
  description = "apply / plan role ARNs (workflows: role-to-assume)"
}

output "passphrase_parameter" {
  value = aws_ssm_parameter.passphrase.name
}
