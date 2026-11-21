# sbomreport-to-dependencytrack (takumakume/sbomreport-to-dependencytrack): receives the Trivy Operator's
# report webhook and uploads every SbomReport (CycloneDX of a running image) to Dependency-Track. Other report
# kinds are skipped. Runs next to Dependency-Track and talks to its api-server inside the cluster.
#
# Projects: <registry>/<repository> (e.g. ghcr.io/dreitier/postfix), version = image tag (digest if untagged),
# no tags, below the parent project <parent_project_name> – separate from the projects of the release pipelines
# (postfix, backmon, …). See docs/dependency-track.md.
#
# API key: own Dependency-Track team trivy-operator (BOM_UPLOAD, PORTFOLIO_MANAGEMENT, PROJECT_CREATION_UPLOAD,
# VIEW_PORTFOLIO), written by hand to OpenBao <api_key_kv_name> (api_key).

locals {
  name       = "sbomreport-to-dependencytrack"
  api_secret = "sbomreport-to-dependencytrack"
}

resource "kubernetes_manifest" "api_key" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata   = { name = local.api_secret, namespace = var.namespace }
    spec = {
      refreshInterval = "1h"
      secretStoreRef  = { kind = "ClusterSecretStore", name = var.secret_store_name }
      target          = { name = local.api_secret, creationPolicy = "Owner" }
      # the chart reads the key "api-key"
      data = [{ secretKey = "api-key", remoteRef = { key = var.api_key_kv_name, property = "api_key" } }]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = var.namespace
  repository = "https://takumakume.github.io/sbomreport-to-dependencytrack/charts"
  chart      = "sbomreport-to-dependencytrack"
  version    = var.chart_version

  values = [yamlencode({
    config = {
      apiKeySecretName  = local.api_secret
      baseUrl           = var.dependency_track_url
      parentProjectName = var.parent_project_name
      # templates with [[ ]] delimiters (Go template + sprig, missingkey=error), the SbomReport is .sbomReport;
      # `get` because digest-pinned images have no artifact.tag
      projectName    = "[[ .sbomReport.report.registry.server ]]/[[ .sbomReport.report.artifact.repository ]]"
      projectVersion = "[[ get .sbomReport.report.artifact \"tag\" | default (get .sbomReport.report.artifact \"digest\") ]]"
      # No tags: the tool sets them AFTER the upload with a full project update (lookup by name/version →
      # POST /api/v1/project). The project from DT 5.2's lookup comes without its parent, so that update detached every image
      # project from "cluster dreitier" and the collection project stayed empty (2026-11-18). Without tags
      # the tool skips the update and the parent set at creation (autoCreate + parentName) stays.
      # (Tags would have to be space-separated anyway: DT_PROJECT_TAGS is split at whitespace by viper.)
      projectTags = ""
      # deleted reports are not sent (Trivy Operator webhookSendDeletedReports = false)
      sbomDeleteAction = "ignore"
    }

    # the chart has no defaults – restricted Pod Security Standard
    podSecurityContext = { runAsNonRoot = true, runAsUser = 10000, seccompProfile = { type = "RuntimeDefault" } }
    securityContext = {
      allowPrivilegeEscalation = false
      readOnlyRootFilesystem   = true
      capabilities             = { drop = ["ALL"] }
    }
    resources = var.resources
  })]

  depends_on = [kubernetes_manifest.api_key]
}
