output "role_arns" {
  value       = { for k, r in aws_iam_role.this : k => r.arn }
  description = "Role ARNs for AWS_ROLE_ARN of the consumers"
}
