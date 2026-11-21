# Workload resources that predate basement: S3 buckets of the applications and the technical IAM users
# (static access keys) that access them. Everything here is imported (import = true). Access keys are
# deliberately not managed – a key created by OpenTofu would put the secret into the state. New workloads
# in the prod cluster use IRSA (aws/irsa-prod) instead of IAM users.

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# --- S3 ---------------------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.buckets : k => v if v.import }
  to       = aws_s3_bucket.this[each.key]
  id       = each.key
}

resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.key

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = { for k, v in var.buckets : k => v if v.import }
  to       = aws_s3_bucket_server_side_encryption_configuration.this[each.key]
  id       = each.key
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = each.value.bucket_key_enabled
  }
}

import {
  for_each = { for k, v in var.buckets : k => v if v.import && v.public_access_block && v.import_public_access_block }
  to       = aws_s3_bucket_public_access_block.this[each.key]
  id       = each.key
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = { for k, v in var.buckets : k => v if v.public_access_block }

  bucket                  = aws_s3_bucket.this[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

import {
  for_each = { for k, v in var.buckets : k => v if v.import && v.versioning != null }
  to       = aws_s3_bucket_versioning.this[each.key]
  id       = each.key
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = { for k, v in var.buckets : k => v if v.versioning != null }

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = each.value.versioning
  }
}

# Retention for backup buckets that are written by append-only clients (e.g. OpenBao snapshots: the
# writer may only PutObject, expiry is up to S3)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = { for k, v in var.buckets : k => v if v.expiration_days != null || v.noncurrent_expiration_days != null }

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    id     = "expire"
    status = "Enabled"
    filter {}

    dynamic "expiration" {
      for_each = each.value.expiration_days != null ? [each.value.expiration_days] : []
      content {
        days = expiration.value
      }
    }
    noncurrent_version_expiration {
      noncurrent_days = coalesce(each.value.expiration_days, each.value.noncurrent_expiration_days)
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --- IAM policies -----------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.policies : k => v if v.import }
  to       = aws_iam_policy.this[each.key]
  id       = "arn:aws:iam::${local.account_id}:policy/${each.key}"
}

resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.key
  description = each.value.description
  policy      = each.value.document
}

# --- IAM users ----------------------------------------------------------------------------------------

import {
  for_each = { for k, v in var.users : k => v if v.import }
  to       = aws_iam_user.this[each.key]
  id       = each.key
}

resource "aws_iam_user" "this" {
  for_each = var.users

  name = each.key
  tags = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  attachments = merge([
    for user, u in var.users : {
      for p in u.policies : "${user}/${p}" => {
        user       = user
        import     = u.import
        policy_arn = startswith(p, "arn:") ? p : "arn:aws:iam::${local.account_id}:policy/${p}"
        managed    = !startswith(p, "arn:")
        policy     = p
      }
    }
  ]...)

  inline_policies = merge([
    for user, u in var.users : {
      for name, doc in u.inline_policies : "${user}/${name}" => { user = user, name = name, document = doc, import = u.import }
    }
  ]...)
}

import {
  for_each = { for k, v in local.attachments : k => v if v.import }
  to       = aws_iam_user_policy_attachment.this[each.key]
  id       = "${each.value.user}/${each.value.policy_arn}"
}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = local.attachments

  user       = aws_iam_user.this[each.value.user].name
  policy_arn = each.value.managed ? aws_iam_policy.this[each.value.policy].arn : each.value.policy_arn
}

import {
  for_each = { for k, v in local.inline_policies : k => v if v.import }
  to       = aws_iam_user_policy.this[each.key]
  id       = "${each.value.user}:${each.value.name}"
}

resource "aws_iam_user_policy" "this" {
  for_each = local.inline_policies

  user   = aws_iam_user.this[each.value.user].name
  name   = each.value.name
  policy = each.value.document
}
