output "client_spaces" {
    description = "The set of spaces in which the broker was made available, if any"
    value = keys(local.spaces_in_orgs)
}
