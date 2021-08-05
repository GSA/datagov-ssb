locals {
  trusted_aws_account = 133032889584
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

resource "aws_route53_zone" "zone" {
  count = var.manage_zone ? 1 : 0
  name  = var.broker_zone
}

module "iam_assumable_roles" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 4.2.0"

  trusted_role_arns = [
    "arn:aws:iam::${local.trusted_aws_account}:root",
  ]

  # Note both of these require MFA by default
  create_admin_role     = true
  create_poweruser_role = true
  admin_role_name       = "ssb-administrator"
  poweruser_role_name   = "ssb-developer"

  poweruser_role_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ]

}

