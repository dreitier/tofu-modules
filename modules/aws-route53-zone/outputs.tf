output "zone_id" {
  value = aws_route53_zone.this.zone_id
}

output "zone_name" {
  value = aws_route53_zone.this.name
}

output "name_servers" {
  value       = aws_route53_delegation_set.this.name_servers
  description = "NS records to set at INWX for the delegation"
}
