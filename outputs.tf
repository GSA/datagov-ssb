output "client_spaces" {
  description = "The set of spaces in which the broker was made available, if any"
  value       = keys(local.spaces_in_orgs)
}

output "route53_zone_nameservers" {
  description = "The nameservers that handle requests for the SSB subdomain"
  value       = aws_route53_zone.zone.name_servers
}
output "route53_sandbox_zone_nameservers" {
  description = "The nameservers that handle requests for the SSB subdomain (in the data.gov sandbox)"
  value       = aws_route53_zone.sandbox_zone.name_servers
}
