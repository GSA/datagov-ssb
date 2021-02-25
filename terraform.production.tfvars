# See vars.tf for more information
client_spaces = {
  gsa-datagov = ["management", "development", "staging", "prod"]
}
broker_space = {
  org   = "gsa-datagov"
  space = "management"
}
broker_zone = "ssb.datagov.us"
manage_zone = true