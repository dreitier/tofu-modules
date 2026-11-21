output "permission_set_arns" {
  value = { for k, p in aws_ssoadmin_permission_set.this : k => p.arn }
}
