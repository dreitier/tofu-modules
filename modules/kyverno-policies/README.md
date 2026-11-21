# kyverno-policies

Kyverno policies (CRs) – the engine and its CRDs come from security/kyverno (modules/kyverno).

- Pod Security Standards from the upstream kyverno-policies chart (CEL ValidatingPolicies, baseline + restricted)
- own ValidatingPolicies (customPolicies of the same chart): no :latest/untagged images, resource requests

Everything starts in Audit with failurePolicy Ignore: violations only end up in PolicyReports, nothing is
blocked and a Kyverno outage never blocks pod creation. Switch single policies to Enforce via
`enforce_policies` once their reports are clean (exceptions first). See docs/kyverno.md.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | kyverno-policies chart version (oci://ghcr.io/kyverno/charts/kyverno-policies), same release line as the kyverno chart | `string` | n/a | yes |
| <a name="input_enforce_policies"></a> [enforce\_policies](#input\_enforce\_policies) | Policy names switched from Audit to Enforce (Deny) – only after their PolicyReports are clean | `list(string)` | `[]` | no |
| <a name="input_excluded_namespace_prefixes"></a> [excluded\_namespace\_prefixes](#input\_excluded\_namespace\_prefixes) | Namespace prefixes the policies ignore (Rancher/Fleet: cattle-*) | `list(string)` | <pre>[<br/>  "cattle-"<br/>]</pre> | no |
| <a name="input_excluded_namespaces"></a> [excluded\_namespaces](#input\_excluded\_namespaces) | Namespaces the policies ignore (admission and background reports) | `list(string)` | <pre>[<br/>  "kube-system",<br/>  "kube-public",<br/>  "kube-node-lease",<br/>  "kyverno",<br/>  "calico-system",<br/>  "tigera-operator",<br/>  "trivy-system"<br/>]</pre> | no |
| <a name="input_failure_policy"></a> [failure\_policy](#input\_failure\_policy) | Webhook failurePolicy of the policies: Ignore while auditing, Fail only for policies that must never be skipped | `string` | `"Ignore"` | no |
| <a name="input_kube_config"></a> [kube\_config](#input\_kube\_config) | Kubeconfig of the cluster (output kube\_config of the cluster unit) | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the Helm release (the policies themselves are cluster-scoped) – the Kyverno namespace | `string` | `"kyverno"` | no |
| <a name="input_pod_security_standard"></a> [pod\_security\_standard](#input\_pod\_security\_standard) | baseline, restricted (= baseline + restricted) or custom | `string` | `"restricted"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
