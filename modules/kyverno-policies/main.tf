# Kyverno policies (CRs) – the engine and its CRDs come from security/kyverno (modules/kyverno).
#
# - Pod Security Standards from the upstream kyverno-policies chart (CEL ValidatingPolicies, baseline + restricted)
# - own ValidatingPolicies (customPolicies of the same chart): no :latest/untagged images, resource requests
#
# Everything starts in Audit with failurePolicy Ignore: violations only end up in PolicyReports, nothing is
# blocked and a Kyverno outage never blocks pod creation. Switch single policies to Enforce via
# `enforce_policies` once their reports are clean (exceptions first). See docs/kyverno.md.

locals {
  # Same exclusion for the upstream and the own policies. CEL matchConditions (no wildcards in namespaceSelector).
  exclude_condition = {
    name = "exclude-system-namespaces"
    expression = format("!(request.namespace in [%s]) && !(%s)",
      join(", ", [for ns in var.excluded_namespaces : "'${ns}'"]),
      join(" || ", concat(["false"], [for p in var.excluded_namespace_prefixes : "request.namespace.startsWith('${p}')"])),
    )
  }

  pod_rules = [{
    apiGroups   = [""]
    apiVersions = ["v1"]
    operations  = ["CREATE", "UPDATE"]
    resources   = ["pods"]
  }]

  # All containers of a pod (regular, init, ephemeral)
  containers_variable = {
    name       = "containers"
    expression = "object.spec.containers + object.spec.?initContainers.orValue([]) + object.spec.?ephemeralContainers.orValue([])"
  }

  custom_policies = {
    disallow-latest-tag = {
      title       = "Disallow latest tag"
      category    = "Best Practices"
      severity    = "medium"
      description = "Images must be pinned to a tag other than latest (or a digest); an untagged image resolves to latest."
      variables   = [local.containers_variable]
      validations = [{
        # Tag present: a ':' after the last '/' (a registry port alone is no tag); digest-pinned images are fine
        expression = "variables.containers.all(c, c.image.contains('@') || (c.image.lastIndexOf(':') > c.image.lastIndexOf('/') && !c.image.endsWith(':latest')))"
        message    = "Images must use a pinned tag other than latest or a digest."
      }]
    }

    require-requests-limits = {
      title       = "Require resource requests and memory limit"
      category    = "Best Practices"
      severity    = "medium"
      description = "Every container needs CPU and memory requests and a memory limit (no CPU limit required)."
      variables   = [{ name = "containers", expression = "object.spec.containers + object.spec.?initContainers.orValue([])" }]
      validations = [{
        expression = "variables.containers.all(c, has(c.resources) && has(c.resources.requests) && 'cpu' in c.resources.requests && 'memory' in c.resources.requests && has(c.resources.limits) && 'memory' in c.resources.limits)"
        message    = "Containers need resources.requests.cpu, resources.requests.memory and resources.limits.memory."
      }]
    }
  }
}

resource "helm_release" "this" {
  name       = "kyverno-policies"
  namespace  = var.namespace
  repository = "oci://ghcr.io/kyverno/charts"
  chart      = "kyverno-policies"
  version    = var.chart_version

  values = [yamlencode({
    # restricted = all baseline + restricted PSS policies; the category annotation tells them apart in the reports
    podSecurityStandard = var.pod_security_standard
    podSecuritySeverity = "medium"

    validationFailureAction         = "Audit"
    validationFailureActionByPolicy = { for p in var.enforce_policies : p => "Enforce" }
    failurePolicy                   = var.failure_policy

    vpolExclude = { matchConditions = [local.exclude_condition] }

    customPolicies = [for name, p in local.custom_policies : {
      apiVersion = "policies.kyverno.io/v1"
      kind       = "ValidatingPolicy"
      metadata = {
        name = name
        annotations = {
          "policies.kyverno.io/title"       = p.title
          "policies.kyverno.io/category"    = p.category
          "policies.kyverno.io/severity"    = p.severity
          "policies.kyverno.io/subject"     = "Pod"
          "policies.kyverno.io/description" = p.description
        }
      }
      spec = {
        failurePolicy     = var.failure_policy
        validationActions = contains(var.enforce_policies, name) ? ["Deny"] : ["Audit"]
        matchConstraints  = { resourceRules = local.pod_rules }
        matchConditions   = [local.exclude_condition]
        variables         = p.variables
        validations       = p.validations
      }
    }]
  })]
}
