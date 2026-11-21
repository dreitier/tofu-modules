# Symmetric KMS key with automatic rotation. Access is granted through IAM policies of the consumers
# (the default key policy delegates to IAM for this account). Deleting or disabling the key makes
# everything encrypted with it unrecoverable → prevent_destroy plus a 30-day deletion window.

resource "aws_kms_key" "this" {
  description             = var.description
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
