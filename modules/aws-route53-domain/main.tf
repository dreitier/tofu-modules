# A domain registered with Route53 and its hosted zone (created by the registrar), including the records.
# Existing domains are imported (zone_id set). The NS and SOA records belong to the zone and are not
# managed as records.

import {
  for_each = var.zone_id == null ? {} : { this = var.zone_id }
  to       = aws_route53_zone.this
  id       = each.value
}

resource "aws_route53_zone" "this" {
  name    = var.domain
  comment = var.comment
  tags    = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = var.zone_id == null ? {} : var.records
  to       = aws_route53_record.this[each.key]
  id       = "${var.zone_id}_${each.value.name == "" ? var.domain : "${each.value.name}.${var.domain}"}_${each.value.type}"
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name == "" ? var.domain : "${each.value.name}.${var.domain}"
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}

import {
  for_each = var.registered && var.zone_id != null ? { this = var.domain } : {}
  to       = aws_route53domains_registered_domain.this[0]
  id       = each.value
}

# Registration (renewal, lock, name servers). Deleting this resource doesn't release the domain.
resource "aws_route53domains_registered_domain" "this" {
  count    = var.registered ? 1 : 0
  provider = aws.us_east_1

  domain_name   = var.domain
  auto_renew    = var.auto_renew
  transfer_lock = var.transfer_lock

  # Contact privacy (WHOIS redaction); the provider default is true
  admin_privacy      = var.contact_privacy
  billing_privacy    = var.contact_privacy
  registrant_privacy = var.contact_privacy
  tech_privacy       = var.contact_privacy

  # Name servers are left as the registrar set them (the zone's own, in the registrar's order)
}
