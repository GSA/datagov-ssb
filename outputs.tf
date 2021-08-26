output "client_spaces" {
  description = "The set of spaces in which the broker was made available, if any"
  value       = keys(local.spaces_in_orgs)
}

output "ns_record" {
  description = "A NS record to place in the parent zone of the SSB subdomain (for delegation)"
  value       = local.ns_record
}

output "ds_record" {
  description = "A DS record to place in the parent zone of the SSB subdomain (for DNSSEC)"
  value       = local.ds_record
}

output "instructions" {
  description = "Instructions for what to do with the DNS record output"
  value       = local.instructions
}