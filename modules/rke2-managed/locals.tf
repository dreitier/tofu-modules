locals {
  # One deployment customization block per agent when tolerations or an override are set; the override's
  # attributes are null when only tolerations are given (unchanged output for tolerations-only callers)
  cluster_agent_customization = var.cluster_agent_customization == null && length(var.agent_tolerations) == 0 ? [] : [{
    override_affinity = try(var.cluster_agent_customization.override_affinity, null)
    resources         = try(var.cluster_agent_customization.resources, null)
  }]
  fleet_agent_customization = var.fleet_agent_customization == null && length(var.agent_tolerations) == 0 ? [] : [{
    override_affinity = try(var.fleet_agent_customization.override_affinity, null)
    resources         = try(var.fleet_agent_customization.resources, null)
  }]

  rancher_token = sensitive(jsondecode(data.http.rancher_login.response_body).token)

  # etcd S3 credential: ID of the managed cloud credential wins over a fixed name. Its keys are not
  # known to Tofu (placeholder + ExternalSecret, main.tf).
  etcd_s3_placeholder = "set-by-external-secrets"
  etcd_s3_region      = try(coalesce(var.etcd_s3_credential.region, var.aws_region), null)
  etcd_s3_cloud_credential_name = (
    length(rancher2_cloud_credential.etcd_s3) > 0
    ? rancher2_cloud_credential.etcd_s3[0].id
    : try(var.etcd.s3.cloud_credential_name, null)
  )

  # Same command the Rancher UI shows for custom clusters, built from the live registration token.
  # --ca-checksum is the SHA-256 of Rancher's CA certificate (setting cacerts).
  registration_tokens = sensitive({ for t in jsondecode(data.http.registration_token.response_body).data : t.name => t.token })
  registration_token  = local.registration_tokens[var.registration_token_name]
  rancher_url_clean   = trimsuffix(var.rancher_url, "/")
  node_command = join(" ", concat(
    # Download first: with `curl | sh` a failed download runs an empty script and cloud-init reports success.
    # With a private Rancher CA the download is --insecure like in Rancher's UI command; the installer then
    # pins the CA via --ca-checksum.
    ["curl -fL --retry 10 --retry-all-errors ${var.rancher_ca_cert_pem == null ? "" : "--insecure "}${local.rancher_url_clean}/system-agent-install.sh -o /root/system-agent-install.sh && sudo sh /root/system-agent-install.sh",
      "--server ${local.rancher_url_clean}",
      "--label 'cattle.io/os=linux'",
    "--token ${local.registration_token}"],
    var.rancher_ca_cert_pem == null ? [] : ["--ca-checksum ${sha256(var.rancher_ca_cert_pem)}"]
  ))

  # Kubeconfig for the platform units. The Rancher proxy rejects large requests ("request body too large",
  # e.g. the release Secret of a CRD chart), so with the authorized cluster endpoint the platform units talk
  # to the API server directly. rancher2_cluster_v2.kube_config is generated once at creation and never
  # refreshed (no ACE contexts when ACE was enabled later), so the direct context is built here: server
  # from local_auth_endpoint.server, CA from the cluster object (data.http.cluster), token from a dedicated
  # cluster-scoped Rancher token (rancher2_token.kube_config). The token of the proxy kubeconfig is not
  # synced to the downstream cluster and is rejected by kube-api-auth.
  kube_config_raw     = rancher2_cluster_v2.this.kube_config
  kube_config_decoded = try(yamldecode(local.kube_config_raw), null)
  kube_config_token   = try(rancher2_token.kube_config[0].token, null)
  cluster_ca_raw      = try(jsondecode(data.http.cluster[0].response_body).caCert, "")
  # caCert is base64-encoded PEM; accept plain PEM as well
  cluster_ca_b64 = startswith(local.cluster_ca_raw, "-----BEGIN") ? base64encode(local.cluster_ca_raw) : local.cluster_ca_raw
  direct_server  = try(var.local_auth_endpoint.server, null)
  direct_name    = "${var.cluster_name}-direct"
  kube_config_use_direct = (
    try(var.local_auth_endpoint.enabled, false) && local.direct_server != null &&
    local.cluster_ca_b64 != "" && local.kube_config_token != null
  )
  kube_config = !local.kube_config_use_direct ? local.kube_config_raw : yamlencode(merge(local.kube_config_decoded, {
    clusters = concat(local.kube_config_decoded.clusters, [{
      name    = local.direct_name
      cluster = { server = local.direct_server, "certificate-authority-data" = local.cluster_ca_b64 }
    }])
    contexts = concat(local.kube_config_decoded.contexts, [{
      name    = local.direct_name
      context = { cluster = local.direct_name, user = local.direct_name }
    }])
    users = concat(local.kube_config_decoded.users, [{
      name = local.direct_name
      user = { token = local.kube_config_token }
    }])
    "current-context" = local.direct_name
  }))

  # Kubeconfig for people: direct API endpoint, login via kubelogin (kubectl oidc-login) against Keycloak.
  # Holds no secret – the ID token is fetched and cached by kubelogin. Cluster, context and user are all named
  # <cluster>-oidc so the file merges into an existing kubeconfig without clashing with Rancher's entries.
  kube_config_oidc = var.oidc_kubeconfig == null || local.direct_server == null || local.cluster_ca_b64 == "" ? null : yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name    = "${var.cluster_name}-oidc"
      cluster = { server = local.direct_server, "certificate-authority-data" = local.cluster_ca_b64 }
    }]
    contexts = [{
      name    = "${var.cluster_name}-oidc"
      context = { cluster = "${var.cluster_name}-oidc", user = "${var.cluster_name}-oidc" }
    }]
    users = [{
      name = "${var.cluster_name}-oidc"
      user = {
        exec = {
          apiVersion      = "client.authentication.k8s.io/v1"
          command         = "kubectl"
          interactiveMode = "IfAvailable"
          args = concat([
            "oidc-login", "get-token",
            "--oidc-issuer-url=${var.oidc_kubeconfig.issuer_url}",
            "--oidc-client-id=${var.oidc_kubeconfig.client_id}",
          ], var.oidc_kubeconfig.extra_args)
        }
      }
    }]
    "current-context" = "${var.cluster_name}-oidc"
  })
}
