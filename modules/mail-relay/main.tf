# SMTP relay for the cluster (Alertmanager, Grafana, Psono, …): Postfix (dreitier/helm-charts postfix)
# without authentication on a ClusterIP service, forwarding to Exchange Online.
# Upstream: the tenant's MX host on port 25 with STARTTLS and no SASL – Exchange accepts the mail through an
# inbound connector bound to the cluster's egress IP (the gateway, all node traffic is NATed through it).
# Basic SMTP AUTH (smtp.office365.com:587) is not used: Microsoft disables it by default end of 2026.
# Manual parts (docs/mail-relay.md): the Exchange connector, the gateway IP in the SPF record.

locals {
  # Postfix inline tables (no files in the image): exact match for MAIL FROM, regexp (Postfix >= 3.7) for the
  # From header. Header checks: first match wins – allowed addresses DUNNO, any other From header REJECT.
  # "$$": main.cf expands $name macros – a literal $ (regex end anchor) must be doubled.
  sender_pattern = join("|", [for a in var.allowed_senders : replace(replace(a, ".", "[.]"), "+", "[+]")])
  sender_restriction_parameters = length(var.allowed_senders) == 0 ? {} : {
    smtpd_sender_restrictions = "check_sender_access inline:{ ${join(", ", [for a in var.allowed_senders : "${a}=OK"])} }, reject"
    header_checks             = "regexp:{ {/^From:(.*[<[:space:]])?(${local.sender_pattern})>?[[:space:]]*$$/ DUNNO}, {/^From:/ REJECT sender not allowed on this relay} }"
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  name       = var.release_name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://dreitier.github.io/helm-charts/"
  chart      = "postfix"
  version    = var.chart_version

  values = [yamlencode({
    smtp = {
      relayHost         = "[${var.relay_host}]:25"
      relayMyhostname   = var.myhostname
      relayUsername     = "" # no SASL: the connector identifies the sender by IP
      relayNetworks     = join(",", var.relay_networks)
      tlsSecurityLevel  = "encrypt" # STARTTLS required (Exchange Online offers it)
      postfixParameters = local.sender_restriction_parameters
    }
    resources = var.resources
  })]

  cleanup_on_fail = true
  atomic          = true
}
