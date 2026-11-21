# GitHub Actions → AWS without stored keys (docs/ci-deploy.md): GitHub's OIDC provider and two roles for the
# workflows of one repository (basement). GitHub Free has no environments for private repositories, so the
# roles are bound to the token's sub claim instead – checked by AWS:
#   tofu-apps       apply – runs on the apply ref (main: push, workflow_dispatch)
#   tofu-apps-plan  plan  – pull requests and the apply ref; reads states, writes only lock files
# Both read the state passphrase of the automated units from SSM (SecureString, written write-only from
# SOPS) – GitHub holds no secret.

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  issuer     = "token.actions.githubusercontent.com"

  # sub claim: repo:<owner>/<repo>:… – or, with GitHub's immutable subject (default for new repositories),
  # repo:<owner>@<owner id>/<repo>@<repo id>:… (gh api repos/<owner>/<repo>/actions/oidc/customization/sub)
  sub_prefix = coalesce(var.subject_prefix, "repo:${var.repository}")
  subjects = {
    apply = ["${local.sub_prefix}:ref:${var.apply_ref}"]
    plan  = ["${local.sub_prefix}:pull_request", "${local.sub_prefix}:ref:${var.apply_ref}"]
  }
  role_names = { apply = "tofu-apps", plan = "tofu-apps-plan" }

  state_objects = [for u in var.automated_units : "arn:aws:s3:::${var.state_bucket}/${u}/tofu.tfstate"]
  lock_objects  = [for u in var.automated_units : "arn:aws:s3:::${var.state_bucket}/${u}/tofu.tfstate.tflock"]
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.issuer}"
  client_id_list = ["sts.amazonaws.com"]
}

# --- State passphrase ---------------------------------------------------------------------------------

ephemeral "sops_file" "secrets" {
  source_file = var.sops_file
}

resource "aws_ssm_parameter" "passphrase" {
  name             = var.passphrase_parameter
  description      = "OpenTofu state passphrase of the automated units (basement, docs/ci-deploy.md)"
  type             = "SecureString"
  value_wo         = ephemeral.sops_file.secrets.data[var.passphrase_sops_key]
  value_wo_version = var.passphrase_version
}

# --- Roles --------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  for_each = local.subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.issuer}:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.subjects

  name                 = local.role_names[each.key]
  description          = "GitHub Actions of ${var.repository}: OpenTofu ${each.key} of the automated units"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "access" {
  for_each = local.subjects

  # The S3 backend lists the bucket (workspaces); keys only, the states are encrypted client-side
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    sid       = "States"
    actions   = each.key == "apply" ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"]
    resources = local.state_objects
  }

  statement {
    sid       = "LockFiles"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = local.lock_objects
  }

  statement {
    sid       = "Passphrase"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.passphrase.arn]
  }

  # SecureString with the AWS managed key alias/aws/ssm, only through SSM
  statement {
    sid       = "PassphraseDecrypt"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${var.aws_region}:${local.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "this" {
  for_each = local.subjects

  name   = "opentofu-${each.key}"
  role   = aws_iam_role.this[each.key].id
  policy = data.aws_iam_policy_document.access[each.key].json
}
