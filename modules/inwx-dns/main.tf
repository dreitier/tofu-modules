# DNS records of the main domain at INWX. The zone itself exists already and is not managed here (no
# inwx_nameserver resource) – only the records below; records created elsewhere (portal, other tools) are
# left alone. An existing record with the same name/type is imported instead of duplicated:
#   terragrunt import 'inwx_nameserver_record.this["<key>"]' <domain>:<record id>
# Records next to their producer where possible (tg-env lesson): this unit only holds the delegation,
# the ACME CNAMEs and records without a Kubernetes/Hetzner producer.

locals {
  # NS delegation of the ACME zone (aws/route53-acme)
  acme_ns = {
    for i, ns in var.acme_name_servers : "acme-ns-${i}" => {
      name = var.acme_zone_label, type = "NS", content = trimsuffix(ns, ".")
    }
  }

  # _acme-challenge.<label> CNAME <label with dashes>.<acme zone>, one per certificate name (a wildcard
  # *.x validates at _acme-challenge.x as well, so intern.example.com covers *.intern.example.com)
  acme_labels = {
    for n in var.acme_challenge_names : n => (n == var.domain ? "" : trimsuffix(n, ".${var.domain}"))
  }
  acme_cnames = {
    for n, label in local.acme_labels : "acme-cname-${n}" => {
      name    = label == "" ? "_acme-challenge" : "_acme-challenge.${label}"
      type    = "CNAME"
      content = "${label == "" ? "apex" : replace(label, ".", "-")}.${var.acme_zone_label}.${var.domain}"
    }
  }

  records = merge(local.acme_ns, local.acme_cnames, var.records)
}

resource "inwx_nameserver_record" "this" {
  for_each = local.records

  domain = var.domain
  # INWX stores and returns the FQDN – a relative name ("acme") shows up as a change on every plan.
  # Labels in the inputs stay relative ("" or "@" = apex); already fully qualified names pass through.
  name = (
    contains(["", "@"], each.value.name) ? var.domain :
    endswith(each.value.name, ".${var.domain}") ? each.value.name : "${each.value.name}.${var.domain}"
  )
  type    = each.value.type
  content = each.value.content
  ttl     = try(each.value.ttl, 3600)
}

# Existing records (created in the INWX portal) taken over instead of duplicated – IDs from
# scripts/inwx-records.sh. Keys must exist in var.records; after the import the entry can stay (no-op).
import {
  for_each = var.imports
  to       = inwx_nameserver_record.this[each.key]
  id       = each.value
}
