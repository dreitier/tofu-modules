# aws-github-actions

GitHub Actions → AWS without stored keys (docs/ci-deploy.md): GitHub's OIDC provider and two roles for the
workflows of one repository (basement). GitHub Free has no environments for private repositories, so the
roles are bound to the token's sub claim instead – checked by AWS:
```text
  tofu-apps       apply – runs on the apply ref (main: push, workflow_dispatch)
  tofu-apps-plan  plan  – pull requests and the apply ref; reads states, writes only lock files
```
Both read the state passphrase of the automated units from SSM (SecureString, written write-only from
SOPS) – GitHub holds no secret.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apply_ref"></a> [apply\_ref](#input\_apply\_ref) | Git ref whose workflow runs (push, workflow\_dispatch) get the apply role | `string` | `"refs/heads/main"` | no |
| <a name="input_automated_units"></a> [automated\_units](#input\_automated\_units) | Unit paths whose states the roles may use (config/config.hcl automated\_units) | `list(string)` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS shared config profile (config/globals/aws.tfvars) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_passphrase_parameter"></a> [passphrase\_parameter](#input\_passphrase\_parameter) | SSM parameter of the automated units' state passphrase | `string` | `"/basement/state-passphrase-apps"` | no |
| <a name="input_passphrase_sops_key"></a> [passphrase\_sops\_key](#input\_passphrase\_sops\_key) | n/a | `string` | `"state_encryption_passphrase_apps"` | no |
| <a name="input_passphrase_version"></a> [passphrase\_version](#input\_passphrase\_version) | Bump after changing the passphrase in SOPS – rewrites the SSM parameter (write-only) | `number` | `1` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | GitHub repository (owner/name) whose workflows may assume the roles | `string` | n/a | yes |
| <a name="input_sops_file"></a> [sops\_file](#input\_sops\_file) | SOPS-encrypted secrets file (config/sops-secrets.yaml), read ephemerally | `string` | n/a | yes |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | State bucket (config/config.hcl state\_bucket\_name) | `string` | n/a | yes |
| <a name="input_subject_prefix"></a> [subject\_prefix](#input\_subject\_prefix) | Prefix of the OIDC sub claim (sub\_claim\_prefix of gh api repos/<repo>/actions/oidc/customization/sub); null = repo:<repository> | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_passphrase_parameter"></a> [passphrase\_parameter](#output\_passphrase\_parameter) | n/a |
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | apply / plan role ARNs (workflows: role-to-assume) |
<!-- END_TF_DOCS -->
