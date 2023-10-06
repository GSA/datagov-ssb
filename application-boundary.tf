data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

module "broker_eks" {
  source = "./broker"

  name                  = "ssb-eks"
  path                  = "./app-eks"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  instances             = 1
  aws_access_key_id     = module.ssb-eks-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-eks-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}

module "broker_smtp" {
  source = "./broker"

  name                  = "ssb-smtp"
  path                  = "./app-smtp"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  aws_access_key_id     = module.ssb-smtp-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-smtp-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
}

# For now we are using a hand-provisioned user-provided service, not managed by Terraform
data "cloudfoundry_space" "broker-space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

resource "cloudfoundry_service_instance" "solrcloud_broker_k8s_cluster" {
  name         = "ssb-solrcloud-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = module.broker_eks.plans["aws-eks-service/raw"]
  tags         = ["k8s"]
  json_params  = "{\"mng_min_capacity\": 1, \"mng_max_capacity\": 1, \"mng_desired_capacity\": 1, \"mng_instance_types\": [\"t2.small\"]}"
  timeouts {
    create = "60m"
    update = "90m" # in case of an EKS destroy/create
    delete = "40m"
  }
  depends_on = [
    module.broker_eks
  ]
}
module "broker_solrcloud" {
  source = "./broker"

  name                  = "ssb-solrcloud"
  path                  = "./app-solrcloud"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  aws_access_key_id     = module.ssb-solr-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-solr-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
  services              = [cloudfoundry_service_instance.solrcloud_broker_k8s_cluster.id]
}

module "broker_airflow" {
  source = "./broker"

  name                  = "ssb-airflow"
  path                  = "./app-airflow"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  enable_ssh            = var.enable_ssh
  memory                = 1024
  aws_access_key_id     = module.ssb-airflow-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-airflow-broker-user.iam_access_key_secret
  aws_zone              = var.broker_zone
  // TODO: Add dependency to EKS, as necessary
  // services              = [cloudfoundry_service_instance.airflow_broker_k8s_cluster.id]
}
