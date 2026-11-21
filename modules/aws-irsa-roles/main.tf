# IAM roles for service accounts (IRSA, docs/irsa.md). Each role trusts exactly one Kubernetes service
# account of the cluster behind the OIDC provider (sub = system:serviceaccount:<ns>:<sa>, aud = STS).

resource "aws_iam_role" "this" {
  for_each = var.roles

  name                 = each.key
  description          = each.value.description
  max_session_duration = 3600
  tags                 = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_host}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
          "${var.oidc_provider_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  for_each = { for k, v in var.roles : k => v if v.policy_json != null }

  name   = each.key
  role   = aws_iam_role.this[each.key].id
  policy = each.value.policy_json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = merge([for k, v in var.roles : { for arn in v.managed_policy_arns : "${k}|${arn}" => { role = k, arn = arn } }]...)

  role       = aws_iam_role.this[each.value.role].name
  policy_arn = each.value.arn
}
