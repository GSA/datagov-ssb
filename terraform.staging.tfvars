# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio-prototyping = ["notify-management-staging", "notify-demo", "notify-staging", "notify-sandbox"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio-prototyping"
  space = "notify-management-staging"
}
broker_zone       = "ssb.notify.gov"
manage_zone       = true
aws_target_region = "us-west-2"
