# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio-prototyping = ["notify-staging", "notify-sandbox"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio-prototyping"
  space = "notify-management-staging"
}
broker_zone       = "notify-staging.rcahearn.net"
manage_zone       = true
aws_target_region = "us-west-2"
