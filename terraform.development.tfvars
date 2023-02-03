# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio-prototyping = ["notify-sandbox"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio-prototyping"
  space = "notify-sandbox"
}
broker_zone       = "notify-dev.rcahearn.net"
manage_zone       = true
name_prefix       = "ssb-devel"
aws_target_region = "us-west-2"
