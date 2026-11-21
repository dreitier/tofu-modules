output "bucket_arns" {
  value = { for k, b in aws_s3_bucket.this : k => b.arn }
}

output "user_arns" {
  value = { for k, u in aws_iam_user.this : k => u.arn }
}
