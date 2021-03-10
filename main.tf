resource "aws_route53_zone" "zone" {
  count = var.manage_zone ? 1 : 0
  name  = var.broker_zone
}

data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

module "broker_aws" {
  source = "./broker"

  name                  = "ssb-aws"
  path                  = "./app-aws"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

module "broker_eks" {
  source = "./broker"

  name                  = "ssb-eks"
  path                  = "./app-eks"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

module "broker_solr" {
  source = "./broker"

  name          = "ssb-solr"
  path          = "./app-solr"
  broker_space  = var.broker_space
  client_spaces = var.client_spaces
  services      = [cloudfoundry_service_instance.k8s_cluster.id]
}
data "cloudfoundry_service" "k8s" {
  name = "aws-eks-service"
}

# This is the back-end k8s instance to be used by the ssb-solr app
resource "cloudfoundry_service_instance" "k8s_cluster" {
  name         = "ssb-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = data.cloudfoundry_service.k8s.service_plans["raw"]
  tags         = ["k8s"]
  depends_on = [
    module.broker_eks.broker_registrations
  ]
}
