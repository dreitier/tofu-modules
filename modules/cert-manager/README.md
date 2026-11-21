# cert-manager

cert-manager (installs its CRDs); the ClusterIssuers live in platform/cluster-issuers. DNS-01 via
Route53 uses IRSA (docs/irsa.md): the controller gets a projected service account token and the AWS_*
env – no static keys.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS\_REGION of the controller (STS/Route53), from config/globals/aws.tfvars | `string` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | cert-manager chart version (keep the deployed one for the import, upgrade separately) | `string` | n/a | yes |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Create ServiceMonitor/PodMonitor objects – needs the Prometheus Operator CRDs (monitoring.coreos.com) in the cluster | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"cert-manager"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources (requests/limits) – set per cluster in stages/infrastructure/kubernetes/<cluster>/resources.tfvars (keys controller, webhook, cainjector) | `any` | <pre>{<br/>  "cainjector": {<br/>    "limits": {<br/>      "memory": "256Mi"<br/>    }<br/>  },<br/>  "controller": {<br/>    "limits": {<br/>      "memory": "256Mi"<br/>    }<br/>  },<br/>  "webhook": {<br/>    "limits": {<br/>      "memory": "128Mi"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_route53_role_arn"></a> [route53\_role\_arn](#input\_route53\_role\_arn) | IRSA role for DNS-01 (aws/irsa-<cluster>, role <cluster>-cert-manager); null = no Route53 access | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
