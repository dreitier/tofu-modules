# cert-manager (installs its CRDs); the ClusterIssuers live in platform/cluster-issuers. DNS-01 via
# Route53 uses IRSA (docs/irsa.md): the controller gets a projected service account token and the AWS_*
# env – no static keys.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version

  values = [yamlencode(merge({
    crds = { enabled = true }
    config = {
      featureGates = { ACMEHTTP01IngressPathTypeExact = false }
    }
    ingressShim = {
      defaultIssuerName = "letsencrypt-prod"
      defaultIssuerKind = "ClusterIssuer"
    }
    # JSON logs (component-base --logging-format), parsed by Alloy (basement config/alloy/workload-logs.alloy)
    extraArgs  = ["--logging-format=json"]
    resources  = var.resources.controller
    webhook    = { resources = var.resources.webhook, extraArgs = ["--logging-format=json"] }
    cainjector = { resources = var.resources.cainjector, extraArgs = ["--logging-format=json"] }
    prometheus = {
      enabled        = true
      servicemonitor = { enabled = var.monitoring_enabled }
    }
    },
    # IRSA for the controller (service account cert-manager/cert-manager) – only with DNS-01 via Route53
    [for arn in compact([var.route53_role_arn]) : {
      extraEnv = [
        { name = "AWS_ROLE_ARN", value = arn },
        { name = "AWS_WEB_IDENTITY_TOKEN_FILE", value = "/var/run/secrets/eks.amazonaws.com/serviceaccount/token" },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_STS_REGIONAL_ENDPOINTS", value = "regional" },
      ]
      volumes = [{
        name = "aws-token"
        projected = {
          sources = [{
            serviceAccountToken = {
              audience          = "sts.amazonaws.com"
              expirationSeconds = 86400
              path              = "token"
            }
          }]
        }
      }]
      volumeMounts = [{
        name      = "aws-token"
        mountPath = "/var/run/secrets/eks.amazonaws.com/serviceaccount"
        readOnly  = true
      }]
    }]...
  ))]

  timeout = 600

  # Removing the release would delete the CRDs and with them every Certificate/Issuer
  lifecycle {
    prevent_destroy = true
  }
}
