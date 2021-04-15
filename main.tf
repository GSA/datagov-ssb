resource "aws_route53_zone" "zone" {
  count = var.manage_zone ? 1 : 0
  name  = var.broker_zone
}

data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

resource "aws_servicequotas_service_quota" "minimum_quotas" {
  for_each = {
    "vpc/L-45FE3B85" = 20 # egress-only internet gateways per region
    "vpc/L-A4707A72" = 20 # internet gateways per region
    "vpc/L-FE5A380F" = 20 # NAT gateways per AZ
    "vpc/L-2AFB9258" = 16 # security groups per network interface (16 is the max)
    "vpc/L-F678F1CE" = 20 # VPCs per region
    "eks/L-33415657" = 20 # Fargate profiles per cluster
    "eks/L-23414FF3" = 10 # label pairs per Fargate profile selector
    "ec2/L-0263D0A3" = 20 # EC2-VPC Elastic IPs
  }
  service_code = element(split("/", each.key), 0)
  quota_code   = element(split("/", each.key), 1)
  value        = each.value
}

module "broker_aws" {
  source = "./broker"

  name                  = "ssb-aws"
  path                  = "./app-aws"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_zone              = var.broker_zone
  depends_on = [
    aws_route53_zone.zone
  ]
}

module "broker_eks" {
  source = "./broker"

  name                  = "ssb-eks"
  path                  = "./app-eks"
  broker_space          = var.broker_space
  client_spaces         = var.client_spaces
  memory                = 512
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_zone              = var.broker_zone
  depends_on = [
    aws_route53_zone.zone
  ]
}

module "broker_solr" {
  source = "./broker"

  name          = "ssb-solr"
  path          = "./app-solr"
  broker_space  = var.broker_space
  client_spaces = var.client_spaces
  services      = [cloudfoundry_service_instance.k8s_cluster.id]
}

# This is the back-end k8s instance to be used by the ssb-solr app
resource "cloudfoundry_service_instance" "k8s_cluster" {
  name         = "ssb-solr-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = module.broker_eks.plans["aws-eks-service/raw"]
  tags         = ["k8s"]
  timeouts {
    create = "40m"
    delete = "30m"
  }
}
