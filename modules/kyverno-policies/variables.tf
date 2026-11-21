variable "kube_config" {
  type        = string
  sensitive   = true
  description = "Kubeconfig of the cluster (output kube_config of the cluster unit)"
}

variable "chart_version" {
  type        = string
  description = "kyverno-policies chart version (oci://ghcr.io/kyverno/charts/kyverno-policies), same release line as the kyverno chart"
}

variable "namespace" {
  type        = string
  description = "Namespace of the Helm release (the policies themselves are cluster-scoped) – the Kyverno namespace"
  default     = "kyverno"
}

variable "pod_security_standard" {
  type        = string
  description = "baseline, restricted (= baseline + restricted) or custom"
  default     = "restricted"
}

variable "failure_policy" {
  type        = string
  description = "Webhook failurePolicy of the policies: Ignore while auditing, Fail only for policies that must never be skipped"
  default     = "Ignore"
}

variable "enforce_policies" {
  type        = list(string)
  description = "Policy names switched from Audit to Enforce (Deny) – only after their PolicyReports are clean"
  default     = []
}

variable "excluded_namespaces" {
  type        = list(string)
  description = "Namespaces the policies ignore (admission and background reports)"
  default     = ["kube-system", "kube-public", "kube-node-lease", "kyverno", "calico-system", "tigera-operator", "trivy-system"]
}

variable "excluded_namespace_prefixes" {
  type        = list(string)
  description = "Namespace prefixes the policies ignore (Rancher/Fleet: cattle-*)"
  default     = ["cattle-"]
}
