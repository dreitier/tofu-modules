# sbomreport-to-dependencytrack

sbomreport-to-dependencytrack (takumakume/sbomreport-to-dependencytrack): receives the Trivy Operator's
report webhook and uploads every SbomReport (CycloneDX of a running image) to Dependency-Track. Other report
kinds are skipped. Runs next to Dependency-Track and talks to its api-server inside the cluster.

Projects: <registry>/<repository> (e.g. ghcr.io/dreitier/postfix), version = image tag (digest if untagged),
no tags, below the parent project <parent_project_name> – separate from the projects of the release pipelines
(postfix, backmon, …). See docs/dependency-track.md.

API key: own Dependency-Track team trivy-operator (BOM_UPLOAD, PORTFOLIO_MANAGEMENT, PROJECT_CREATION_UPLOAD,
VIEW_PORTFOLIO), written by hand to OpenBao <api_key_kv_name> (api_key).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_key_kv_name"></a> [api\_key\_kv\_name](#input\_api\_key\_kv\_name) | OpenBao entry with the API key of the Dependency-Track team trivy-operator (property api\_key) | `string` | `"k8s/prod/dependency-track-sbomreport"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | sbomreport-to-dependencytrack chart version (https://takumakume.github.io/sbomreport-to-dependencytrack/charts) | `string` | n/a | yes |
| <a name="input_dependency_track_url"></a> [dependency\_track\_url](#input\_dependency\_track\_url) | In-cluster URL of the Dependency-Track api-server | `string` | `"http://dependency-track-api-server.dependency-track.svc:8080"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (exists – apps/dependency-track) | `string` | `"dependency-track"` | no |
| <a name="input_parent_project_name"></a> [parent\_project\_name](#input\_parent\_project\_name) | Parent project of all image projects – must exist in Dependency-Track (created by hand) | `string` | `"cluster dreitier"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Kubernetes resources | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "128Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "32Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_secret_store_name"></a> [secret\_store\_name](#input\_secret\_store\_name) | n/a | `string` | `"openbao"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_webhook_url"></a> [webhook\_url](#output\_webhook\_url) | Webhook URL for the Trivy Operator (operator.webhookBroadcastURL) |
<!-- END_TF_DOCS -->
