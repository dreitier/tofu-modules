# aws-oidc-issuer

Public OIDC issuer for an on-prem Kubernetes cluster (IRSA, docs/irsa.md): S3 serves the discovery
document and the JWKS, IAM trusts the issuer. Only public keys are published; the bucket allows
GetObject on these two objects and nothing else (no listing).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | S3 bucket that serves the OIDC discovery document and JWKS (its URL is the issuer) | `string` | n/a | yes |
| <a name="input_client_ids"></a> [client\_ids](#input\_client\_ids) | Audiences accepted by the IAM OIDC provider | `list(string)` | <pre>[<br/>  "sts.amazonaws.com"<br/>]</pre> | no |
| <a name="input_jwks_json"></a> [jwks\_json](#input\_jwks\_json) | JWKS of the cluster's service account signing key (kubectl get --raw /openid/v1/jwks). null on the<br/>first apply of a new cluster: the issuer URL only depends on the bucket, so the cluster can be<br/>created with it before the JWKS exists (docs/bootstrap.md). | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_issuer_url"></a> [issuer\_url](#output\_issuer\_url) | Value for kube-apiserver --service-account-issuer |
| <a name="output_jwks_uri"></a> [jwks\_uri](#output\_jwks\_uri) | Value for kube-apiserver --service-account-jwks-uri |
| <a name="output_provider_arn"></a> [provider\_arn](#output\_provider\_arn) | IAM OIDC provider, principal of the IRSA role trust policies |
| <a name="output_provider_host"></a> [provider\_host](#output\_provider\_host) | Issuer without scheme, prefix of the trust policy condition keys (<host>:sub, <host>:aud) |
<!-- END_TF_DOCS -->
