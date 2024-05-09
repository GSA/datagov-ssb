# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio = ["notify-sandbox"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio"
  space = "notify-sandbox"
}
broker_zone       = "dev.ssb.notify.gov"
manage_zone       = true
name_prefix       = "ssb-devel"
aws_target_region = "us-west-2"
