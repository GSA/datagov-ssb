data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

module "broker_smtp" {
  source = "./broker"

  name                  = "${var.name_prefix}-smtp"
  path                  = "./app-smtp"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  broker_db_plan_name   = var.broker_db_plan_name
  aws_access_key_id     = module.ssb-smtp-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-smtp-broker-user.iam_access_key_secret
  aws_region            = var.aws_target_region
  aws_zone              = var.broker_zone
}
