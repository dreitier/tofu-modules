# Dedicated Route53 zone (e.g. acme.example.com) for the ACME DNS-01 delegation: the main domain stays
# at INWX, its _acme-challenge records are CNAMEs into this zone. A reusable delegation set keeps the
# name servers stable even if the zone is ever recreated (the NS records at INWX would break otherwise).

resource "aws_route53_delegation_set" "this" {
  reference_name = var.zone_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_zone" "this" {
  name              = var.zone_name
  comment           = var.comment
  delegation_set_id = aws_route53_delegation_set.this.id
  tags              = var.tags

  lifecycle {
    prevent_destroy = true
  }
}
