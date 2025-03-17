# For now we are using a hand-provisioned user-provided service, not managed by Terraform
data "cloudfoundry_space" "broker-space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

module "broker_smtp" {
  source = "./broker"

  name                  = "ssb-smtp"
  path                  = "./app-smtp"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  aws_access_key_id     = module.ssb-smtp-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-smtp-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}

module "broker_solrcloud" {
  source = "./broker"

  name                  = "ssb-solrcloud"
  path                  = "./app-solr"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  aws_access_key_id     = module.ssb-solr-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-solr-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}
