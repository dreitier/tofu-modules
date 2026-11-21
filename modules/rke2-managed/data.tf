data "sops_file" "credentials" {
  source_file = var.sops_file
}

# Logs in to Rancher with username/password on every plan/apply and returns a
# short-lived token for the rancher2 provider. No long-lived API key is required.
data "http" "rancher_login" {
  url    = "${trimsuffix(var.rancher_url, "/")}${var.rancher_login_path}"
  method = "POST"

  # The http provider rejects "insecure" and "ca_cert_pem" together (even insecure = false),
  # so only the one in use is set
  insecure    = var.rancher_insecure ? true : null
  ca_cert_pem = var.rancher_insecure ? null : var.rancher_ca_cert_pem

  request_headers = {
    Accept       = "application/json"
    Content-Type = "application/json"
  }

  request_body = jsonencode({
    username     = var.rancher_admin_user
    password     = data.sops_file.credentials.data[var.rancher_password_sops_key]
    ttl          = var.rancher_token_ttl_minutes * 60 * 1000
    description  = "OpenTofu (${var.cluster_name})"
    responseType = "json"
  })

  lifecycle {
    postcondition {
      condition     = contains([200, 201], self.status_code)
      error_message = "Login to Rancher failed with HTTP status ${self.status_code}."
    }
  }
}

# Current registration token of the cluster, read on every plan/apply. The provider's
# cluster_registration_token attribute keeps a value that went stale after Rancher replaced the
# token (2026-10-26: "500 machine not found by request"), so the node command is built from this.
data "http" "registration_token" {
  url    = "${trimsuffix(var.rancher_url, "/")}/v3/clusterregistrationtokens?clusterId=${rancher2_cluster_v2.this.cluster_v1_id}"
  method = "GET"

  depends_on = [kubernetes_manifest.registration_token]

  insecure    = var.rancher_insecure ? true : null
  ca_cert_pem = var.rancher_insecure ? null : var.rancher_ca_cert_pem

  request_headers = {
    Accept        = "application/json"
    Authorization = "Bearer ${local.rancher_token}"
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 && contains([for t in jsondecode(self.response_body).data : t.name], var.registration_token_name)
      error_message = "Registration token ${var.registration_token_name} of the cluster not found (HTTP ${self.status_code})."
    }
  }
}

# Cluster object (v3 API) for the CA of the downstream API server – needed for the direct kubeconfig
# (locals.tf, authorized cluster endpoint).
data "http" "cluster" {
  count  = try(var.local_auth_endpoint.server, null) == null ? 0 : 1
  url    = "${trimsuffix(var.rancher_url, "/")}/v3/clusters/${rancher2_cluster_v2.this.cluster_v1_id}"
  method = "GET"

  insecure    = var.rancher_insecure ? true : null
  ca_cert_pem = var.rancher_insecure ? null : var.rancher_ca_cert_pem

  request_headers = {
    Accept        = "application/json"
    Authorization = "Bearer ${local.rancher_token}"
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Reading cluster ${rancher2_cluster_v2.this.cluster_v1_id} from Rancher failed (HTTP ${self.status_code})."
    }
  }
}
