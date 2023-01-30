# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio-prototyping = ["notify-sandbox"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio-prototyping"
  space = "notify-sandbox"
}
# broker_zone = "ssb-dev.notify.gov"
broker_zone       = "notify-dev.rcahearn.net"
manage_zone       = true
aws_target_region = "us-west-2"
