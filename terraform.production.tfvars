# See vars.tf for more information
client_spaces = {
  gsa-tts-benefits-studio-prototyping = ["notify-management", "notify-prod", "notify-demo"]
}
broker_space = {
  org   = "gsa-tts-benefits-studio-prototyping"
  space = "notify-management"
}
broker_zone         = "ssb.notify.gov"
manage_zone         = false
enable_ssh          = false
broker_db_plan_name = "small-mysql-redundant"
aws_target_region   = "us-gov-west-1"
