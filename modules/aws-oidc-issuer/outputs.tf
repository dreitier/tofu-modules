output "issuer_url" {
  value       = local.issuer_url
  description = "Value for kube-apiserver --service-account-issuer"
}

output "jwks_uri" {
  value       = local.discovery.jwks_uri
  description = "Value for kube-apiserver --service-account-jwks-uri"
}

output "provider_arn" {
  value       = aws_iam_openid_connect_provider.this.arn
  description = "IAM OIDC provider, principal of the IRSA role trust policies"
}

output "provider_host" {
  value       = trimprefix(local.issuer_url, "https://")
  description = "Issuer without scheme, prefix of the trust policy condition keys (<host>:sub, <host>:aud)"
}
