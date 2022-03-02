locals {
  trusted_aws_account_id = 657786969144 # <- tts-prod (parameterize later)
  this_aws_account_id    = data.aws_caller_identity.current.account_id
  ns_record              = var.manage_zone ? tolist(["NS", var.broker_zone, "[ ${join(", \n", [for s in aws_route53_zone.zone[0].name_servers : format("%q", s)])} ]"]) : null
  ds_record              = var.manage_zone ? tolist(["DS", var.broker_zone, aws_route53_key_signing_key.zone[0].ds_record]) : null
  instructions           = var.manage_zone ? "Create NS and DS records in the ${regex("\\..*", var.broker_zone)} zone with the values indicated." : null
}

# Static deployment of EKS in the managed boundary. This gets bound to the
# ssb-solrcloud broker app, and it's where SolrCloud instances are created.
module "brokerpak-eks-terraform" {
  source = "github.com/GSA/datagov-brokerpak-eks//terraform?ref=main"
  providers = {
    aws                     = aws.eks-terraform
    aws.dnssec-key-provider = aws.dnssec-key-provider
  }
  aws_access_key_id     = module.ssb-eks-broker-user.iam_access_key_id
  aws_secret_access_key = module.ssb-eks-broker-user.iam_access_key_secret
  write_kubeconfig      = true
  subdomain             = var.eks_terraform_subdomain
  region                = var.eks_terraform_region
  zone                  = var.broker_zone
  instance_name         = var.eks_terraform_instance_name
  mng_min_capacity      = var.eks_terraform_mng_min_capacity
  mng_max_capacity      = var.eks_terraform_mng_max_capacity
  mng_desired_capacity  = var.eks_terraform_mng_desired_capacity
}

data "aws_caller_identity" "current" {}

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

# If we're to manage the DNS, create a Route53 zone and set up DNSSEC on it.
resource "aws_route53_zone" "zone" {
  count = var.manage_zone ? 1 : 0
  name  = var.broker_zone
}

# Create a KMS key for DNSSEC signing
resource "aws_kms_key" "zone" {
  count = var.manage_zone ? 1 : 0

  # See Route53 key requirements here: 
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-cmk-requirements.html
  provider                 = aws.dnssec-key-provider # Only us-east-1 is supported
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service",
        Resource = "*"
      },
      {
        Action = "kms:CreateGrant",
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "*"
        Sid      = "IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

# Make it easier for admins to identify the key in the KMS console
resource "aws_kms_alias" "zone" {
  count         = var.manage_zone ? 1 : 0
  provider      = aws.dnssec-key-provider
  name          = "alias/DNSSEC-${split(".", var.broker_zone)[0]}"
  target_key_id = aws_kms_key.zone[count.index].key_id
}

resource "aws_route53_key_signing_key" "zone" {
  count                      = var.manage_zone ? 1 : 0
  hosted_zone_id             = aws_route53_zone.zone[count.index].id
  key_management_service_arn = aws_kms_key.zone[count.index].arn
  name                       = var.broker_zone
}

resource "aws_route53_hosted_zone_dnssec" "zone" {
  count = var.manage_zone ? 1 : 0
  depends_on = [
    aws_route53_key_signing_key.zone[0]
  ]
  hosted_zone_id = aws_route53_key_signing_key.zone[count.index].hosted_zone_id
}


module "assumable_admin_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.5.0"
  trusted_role_arns = [
    "arn:aws:iam::${local.trusted_aws_account_id}:root",
  ]
  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:SetSourceIdentity"
  ]

  create_role         = true
  role_name           = "SSBAdmin"
  attach_admin_policy = true

  # MFA is enforced at the jump account, not here
  role_requires_mfa = false

  tags = {
    Role = "Admin"
  }
}

module "assumable_poweruser_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.5.0"
  trusted_role_arns = [
    "arn:aws:iam::${local.trusted_aws_account_id}:root",
  ]
  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:SetSourceIdentity"
  ]

  create_role             = true
  role_name               = "SSBDev"
  attach_poweruser_policy = true

  # MFA is enforced at the jump account, not here
  role_requires_mfa = false

  tags = {
    Role = "PowerUser"
  }
}

module "ssb-smtp-broker-user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4.2.0"

  create_iam_user_login_profile = false
  force_destroy                 = true
  name                          = "ssb-smtp-broker"
}

resource "aws_iam_user_policy_attachment" "smtp_broker_policies" {
  for_each = toset([
    // ACM manager: for aws_acm_certificate, aws_acm_certificate_validation
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",

    // Route53 manager: for aws_route53_record, aws_route53_zone
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",

    // AWS SES policy defined below
    "arn:aws:iam::${local.this_aws_account_id}:policy/${module.smtp_broker_policy.name}",

    // Uncomment if we are still missing stuff and need to get it working again
    // "arn:aws:iam::aws:policy/AdministratorAccess"
  ])
  user       = module.ssb-smtp-broker-user.iam_user_name
  policy_arn = each.key
}

module "smtp_broker_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.2.0"

  name        = "smtp_broker"
  path        = "/"
  description = "SMTP broker policy (covers SES, IAM, and supplementary Route53)"

  policy = <<-EOF
  {
    "Version":"2012-10-17",
    "Statement":
      [
        {
          "Effect":"Allow",
          "Action":[
            "ses:*"
          ],
          "Resource":"*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "iam:CreateUser",
              "iam:DeleteUser",
              "iam:GetUser",

              "iam:CreateAccessKey",
              "iam:DeleteAccessKey",

              "iam:GetUserPolicy",
              "iam:PutUserPolicy",
              "iam:DeleteUserPolicy",

              "iam:CreatePolicy",
              "iam:DeletePolicy",
              "iam:GetPolicy",
              "iam:AttachUserPolicy",
              "iam:DetachUserPolicy",

              "iam:List*"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "route53:ListHostedZones"
          ],
          "Resource": "*"
        }
    ]
  }
  EOF
}



module "ssb-eks-broker-user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4.2.0"

  create_iam_user_login_profile = false
  force_destroy                 = true
  name                          = "ssb-eks-broker"
}

resource "aws_iam_user_policy_attachment" "eks_broker_policies" {
  for_each = toset([
    // ACM manager: for aws_acm_certificate, aws_acm_certificate_validation
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",

    // EKS manager: for aws_eks_cluster
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",

    // EKS: manipulate node groups
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",

    // Route53 manager: for aws_route53_record, aws_route53_zone
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",

    // WAF2: for aws_wafv2_web_acl
    "arn:aws:iam::aws:policy/AWSWAFFullAccess",

    // AWS EKS module policy defined below
    "arn:aws:iam::${local.this_aws_account_id}:policy/${module.eks_module_policy.name}",

    // AWS EKS brokerpak policy defined below
    "arn:aws:iam::${local.this_aws_account_id}:policy/${module.eks_brokerpak_policy.name}",

    // AWS EKS brokerpak policy for persistent volumes defined below
    "arn:aws:iam::${local.this_aws_account_id}:policy/${module.eks_brokerpak_pv_policy.name}",

    // Uncomment if we are still missing stuff and need to get it working again
    // "arn:aws:iam::aws:policy/AdministratorAccess"
  ])
  user       = module.ssb-eks-broker-user.iam_user_name
  policy_arn = each.key
}

module "eks_brokerpak_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.2.0"

  name        = "eks_brokerpak_policy"
  path        = "/"
  description = "Policy granting additional permissions needed by the EKS brokerpak"
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteVpcEndpoints",
              "eks:CreateAddon",
              "eks:DeleteAddon",
              "eks:ListAddons",
              "eks:UpdateAddon",
              "eks:DescribeAddon",
              "eks:DescribeAddonVersions",
              "eks:CreateNodegroup",
              "eks:DescribeNodegroup",
              "eks:ListNodegroups",
              "eks:UpdateNodegroupConfig",
              "eks:UpdateNodegroupVersion"
            ],
            "Resource": "*"
          }
      ]
    }
  EOF
}

module "eks_brokerpak_pv_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.2.0"

  name        = "eks_brokerpak_pv_policy"
  path        = "/"
  description = "Policy granting additional permissions needed by the EKS brokerpak for Persistent Volumes"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateTags"
        ],
        "Resource": [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ],
        "Condition": {
          "StringEquals": {
            "ec2:CreateAction": [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteTags"
        ],
        "Resource": [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "aws:RequestTag/CSIVolumeName": "*"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "aws:RequestTag/kubernetes.io/cluster/*": "owned"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "ec2:ResourceTag/CSIVolumeName": "*"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteVolume"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteSnapshot"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteSnapshot"
        ],
        "Resource": "*",
        "Condition": {
          "StringLike": {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
          }
        }
      }
    ]
  }
  EOF
}


module "eks_module_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.2.0"

  name        = "eks_module_policy"
  path        = "/"
  description = "Policy granting permissions needed by the AWS EKS Terraform module"

  # The policy content below comes from the URL below on 2021/08/09: 
  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/iam-permissions.md
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "autoscaling:AttachInstances",
                    "autoscaling:CreateAutoScalingGroup",
                    "autoscaling:CreateLaunchConfiguration",
                    "autoscaling:CreateOrUpdateTags",
                    "autoscaling:DeleteAutoScalingGroup",
                    "autoscaling:DeleteLaunchConfiguration",
                    "autoscaling:DeleteTags",
                    "autoscaling:Describe*",
                    "autoscaling:DetachInstances",
                    "autoscaling:SetDesiredCapacity",
                    "autoscaling:UpdateAutoScalingGroup",
                    "autoscaling:SuspendProcesses",
                    "ec2:AllocateAddress",
                    "ec2:AssignPrivateIpAddresses",
                    "ec2:Associate*",
                    "ec2:AttachInternetGateway",
                    "ec2:AttachNetworkInterface",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:CreateDefaultSubnet",
                    "ec2:CreateDhcpOptions",
                    "ec2:CreateEgressOnlyInternetGateway",
                    "ec2:CreateInternetGateway",
                    "ec2:CreateNatGateway",
                    "ec2:CreateNetworkInterface",
                    "ec2:CreateRoute",
                    "ec2:CreateRouteTable",
                    "ec2:CreateSecurityGroup",
                    "ec2:CreateSubnet",
                    "ec2:CreateTags",
                    "ec2:CreateVolume",
                    "ec2:CreateVpc",
                    "ec2:CreateVpcEndpoint",
                    "ec2:DeleteDhcpOptions",
                    "ec2:DeleteEgressOnlyInternetGateway",
                    "ec2:DeleteInternetGateway",
                    "ec2:DeleteNatGateway",
                    "ec2:DeleteNetworkInterface",
                    "ec2:DeleteRoute",
                    "ec2:DeleteRouteTable",
                    "ec2:DeleteSecurityGroup",
                    "ec2:DeleteSubnet",
                    "ec2:DeleteTags",
                    "ec2:DeleteVolume",
                    "ec2:DeleteVpc",
                    "ec2:DeleteVpnGateway",
                    "ec2:Describe*",
                    "ec2:DetachInternetGateway",
                    "ec2:DetachNetworkInterface",
                    "ec2:DetachVolume",
                    "ec2:Disassociate*",
                    "ec2:ModifySubnetAttribute",
                    "ec2:ModifyVpcAttribute",
                    "ec2:ModifyVpcEndpoint",
                    "ec2:ReleaseAddress",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
                    "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
                    "ec2:CreateLaunchTemplate",
                    "ec2:CreateLaunchTemplateVersion",
                    "ec2:DeleteLaunchTemplate",
                    "ec2:DeleteLaunchTemplateVersions",
                    "ec2:DescribeLaunchTemplates",
                    "ec2:DescribeLaunchTemplateVersions",
                    "ec2:GetLaunchTemplateData",
                    "ec2:ModifyLaunchTemplate",
                    "ec2:RunInstances",
                    "eks:CreateCluster",
                    "eks:DeleteCluster",
                    "eks:DescribeCluster",
                    "eks:ListClusters",
                    "eks:UpdateClusterConfig",
                    "eks:UpdateClusterVersion",
                    "eks:DescribeUpdate",
                    "eks:TagResource",
                    "eks:UntagResource",
                    "eks:ListTagsForResource",
                    "eks:CreateFargateProfile",
                    "eks:DeleteFargateProfile",
                    "eks:DescribeFargateProfile",
                    "eks:ListFargateProfiles",
                    "eks:CreateNodegroup",
                    "eks:DeleteNodegroup",
                    "eks:DescribeNodegroup",
                    "eks:ListNodegroups",
                    "eks:UpdateNodegroupConfig",
                    "eks:UpdateNodegroupVersion",
                    "iam:AddRoleToInstanceProfile",
                    "iam:AttachRolePolicy",
                    "iam:CreateInstanceProfile",
                    "iam:CreateOpenIDConnectProvider",
                    "iam:CreateServiceLinkedRole",
                    "iam:CreatePolicy",
                    "iam:CreatePolicyVersion",
                    "iam:CreateRole",
                    "iam:DeleteInstanceProfile",
                    "iam:DeleteOpenIDConnectProvider",
                    "iam:DeletePolicy",
                    "iam:DeletePolicyVersion",
                    "iam:DeleteRole",
                    "iam:DeleteRolePolicy",
                    "iam:DeleteServiceLinkedRole",
                    "iam:DetachRolePolicy",
                    "iam:GetInstanceProfile",
                    "iam:GetOpenIDConnectProvider",
                    "iam:GetPolicy",
                    "iam:GetPolicyVersion",
                    "iam:GetRole",
                    "iam:GetRolePolicy",
                    "iam:List*",
                    "iam:PassRole",
                    "iam:PutRolePolicy",
                    "iam:RemoveRoleFromInstanceProfile",
                    "iam:TagOpenIDConnectProvider",
                    "iam:TagRole",
                    "iam:UntagRole",
                    "iam:UpdateAssumeRolePolicy",
                    "logs:CreateLogGroup",
                    "logs:DescribeLogGroups",
                    "logs:DeleteLogGroup",
                    "logs:ListTagsLogGroup",
                    "logs:PutRetentionPolicy",
                    "kms:CreateAlias",
                    "kms:CreateGrant",
                    "kms:CreateKey",
                    "kms:DeleteAlias",
                    "kms:DescribeKey",
                    "kms:GetKeyPolicy",
                    "kms:GetKeyRotationStatus",
                    "kms:ListAliases",
                    "kms:ListResourceTags",
                    "kms:ScheduleKeyDeletion"
                ],
                "Resource": "*"
            }
        ]
    }
  EOF
}
