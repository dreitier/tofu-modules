# arc-runners

Runner scale sets of dreitier/basement for the OpenTofu deployments of our own apps (docs/ci-deploy.md):
```text
  basement-plan   service account tofu-apps-plan:  read-only on the app namespaces
  basement-apply  service account tofu-apps-apply: role tofu-app in the app namespaces
```
The Kubernetes rights belong to the runner pod's service account (the provider's in-cluster config); AWS
(state, passphrase) comes from GitHub OIDC (aws/github-actions). Jobs run directly in the runner image
(ghcr.io/dreitier/actions-runner-tofu) – no container mode, no Docker, Pod Security "restricted".
Namespace: created by platform/arc-controller (Pod Security "restricted" enforced).
GitHub App (installed on basement only): OpenBao <github_app_kv_name> (app_id, installation_id, private_key).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_namespaces"></a> [app\_namespaces](#input\_app\_namespaces) | Namespaces of the automated apps (they must exist – created by the apps' first manual apply) | `list(string)` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | gha-runner-scale-set chart version (same as the controller's) | `string` | n/a | yes |
| <a name="input_controller_service_account"></a> [controller\_service\_account](#input\_controller\_service\_account) | Service account of the controller (output of platform/arc-controller) | <pre>object({<br/>    namespace = string<br/>    name      = string<br/>  })</pre> | n/a | yes |
| <a name="input_github_app_kv_name"></a> [github\_app\_kv\_name](#input\_github\_app\_kv\_name) | OpenBao entry of the ARC GitHub App (app\_id, installation\_id, private\_key) | `string` | `"k8s/prod/arc-github-app"` | no |
| <a name="input_github_config_url"></a> [github\_config\_url](#input\_github\_config\_url) | Repository whose workflows the runners serve | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the scale sets (output runners\_namespace of platform/arc-controller) | `string` | n/a | yes |
| <a name="input_runner_image"></a> [runner\_image](#input\_runner\_image) | Runner image (ghcr.io/dreitier/actions-runner-tofu) | `string` | n/a | yes |
| <a name="input_runner_resources"></a> [runner\_resources](#input\_runner\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "2Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "512Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_scale_sets"></a> [scale\_sets](#input\_scale\_sets) | plan and/or apply – the key decides the rights (read-only / tofu-app) | <pre>map(object({<br/>    max_runners = optional(number, 1)<br/>  }))</pre> | <pre>{<br/>  "apply": {},<br/>  "plan": {}<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
