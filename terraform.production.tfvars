# See vars.tf for more information
client_spaces = {
  gsa-datagov = ["management", "staging", "prod", "development"]
}
broker_space = {
  org   = "gsa-datagov"
  space = "management"
}
broker_zone = "ssb.data.gov"
manage_zone = true
enable_ssh  = false
