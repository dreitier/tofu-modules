# arc-controller

Actions Runner Controller (gha-runner-scale-set-controller) – installs the CRDs (AutoscalingRunnerSet, …), so
the runner scale sets are a separate unit (platform/arc-runners). The controller only watches the runners'
namespace (Role instead of ClusterRole), which is created here too. docs/ci-deploy.md

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | gha-runner-scale-set-controller chart version (oci://ghcr.io/actions/actions-runner-controller-charts) | `string` | n/a | yes |
| <a name="input_controller_name"></a> [controller\_name](#input\_controller\_name) | Release fullname and service account of the controller (referenced by the scale sets) | `string` | `"arc-controller"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"arc-systems"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | n/a | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "256Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "20m",<br/>    "memory": "64Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_watch_namespace"></a> [watch\_namespace](#input\_watch\_namespace) | Namespace of the runner scale sets (created here, used by platform/arc-runners) | `string` | `"arc-runners"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_controller_service_account"></a> [controller\_service\_account](#output\_controller\_service\_account) | Controller service account (controllerServiceAccount of the scale sets) |
| <a name="output_runners_namespace"></a> [runners\_namespace](#output\_runners\_namespace) | Namespace of the runner scale sets |
<!-- END_TF_DOCS -->
