# Public OIDC issuer for an on-prem Kubernetes cluster (IRSA, docs/irsa.md): S3 serves the discovery
# document and the JWKS, IAM trusts the issuer. Only public keys are published; the bucket allows
# GetObject on these two objects and nothing else (no listing).

locals {
  issuer_url    = "https://${aws_s3_bucket.this.bucket_regional_domain_name}"
  jwks_key      = "openid/v1/jwks"
  discovery_key = ".well-known/openid-configuration"

  discovery = {
    issuer                                = local.issuer_url
    jwks_uri                              = "${local.issuer_url}/${local.jwks_key}"
    response_types_supported              = ["id_token"]
    subject_types_supported               = ["public"]
    id_token_signing_alg_values_supported = ["RS256"]
  }
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ACLs stay blocked; only the bucket policy below grants public read
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadOidcDocuments"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource = [
        "${aws_s3_bucket.this.arn}/${local.discovery_key}",
        "${aws_s3_bucket.this.arn}/${local.jwks_key}",
      ]
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_object" "discovery" {
  bucket        = aws_s3_bucket.this.id
  key           = local.discovery_key
  content       = jsonencode(local.discovery)
  content_type  = "application/json"
  cache_control = "max-age=300"
}

resource "aws_s3_object" "jwks" {
  count = var.jwks_json == null ? 0 : 1

  bucket        = aws_s3_bucket.this.id
  key           = local.jwks_key
  content       = jsonencode(jsondecode(var.jwks_json))
  content_type  = "application/json"
  cache_control = "max-age=300"
}

# Thumbprints are not needed: IAM verifies S3's certificate against its trusted CAs
resource "aws_iam_openid_connect_provider" "this" {
  url            = local.issuer_url
  client_id_list = var.client_ids
  tags           = var.tags

  depends_on = [aws_s3_object.discovery, aws_s3_object.jwks, aws_s3_bucket_policy.public_read]
}
