locals {
  trusted_aws_account_id = 657786969144 # <- tts-prod (parameterize later)
  this_aws_account_id    = data.aws_caller_identity.current.account_id
  ns_record              = var.manage_zone ? tolist(["NS", var.broker_zone, "[ ${join(", \n", [for s in aws_route53_zone.zone[0].name_servers : format("%q", s)])} ]"]) : null
  ds_record              = var.manage_zone ? tolist(["DS", var.broker_zone, aws_route53_key_signing_key.zone[0].ds_record]) : null
  instructions           = var.manage_zone ? "Create NS and DS records in the ${regex("\\..*", var.broker_zone)} zone with the values indicated." : null
}

data "aws_caller_identity" "current" {}

# Quotas defined in:
# SES: https://docs.aws.amazon.com/general/latest/gr/ses.html
# SNS: https://docs.aws.amazon.com/general/latest/gr/sns.html
# I think this probably makes more sense to set within the brokerpak
# resource "aws_servicequotas_service_quota" "minimum_quotas" {
#   for_each = {
#     "ses/L-804C8AE8" = 200 # daily email sends in the current region
#     "ses/L-CDEF9B6B" = 1 # per-second email sends in the current region
#   }
#   service_code = element(split("/", each.key), 0)
#   quota_code   = element(split("/", each.key), 1)
#   value        = each.value
# }

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


# module "assumable_admin_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "~> 4.5.0"
#   trusted_role_arns = [
#     "arn:aws:iam::${local.trusted_aws_account_id}:root",
#   ]
#   trusted_role_actions = [
#     "sts:AssumeRole",
#     "sts:SetSourceIdentity"
#   ]

#   create_role         = true
#   role_name           = "SSBAdmin"
#   attach_admin_policy = true

#   # MFA is enforced at the jump account, not here
#   role_requires_mfa = false

#   tags = {
#     Role = "Admin"
#   }
# }

# module "assumable_poweruser_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "~> 4.5.0"
#   trusted_role_arns = [
#     "arn:aws:iam::${local.trusted_aws_account_id}:root",
#   ]
#   trusted_role_actions = [
#     "sts:AssumeRole",
#     "sts:SetSourceIdentity"
#   ]

#   create_role             = true
#   role_name               = "SSBDev"
#   attach_poweruser_policy = true

#   # MFA is enforced at the jump account, not here
#   role_requires_mfa = false

#   tags = {
#     Role = "PowerUser"
#   }
# }

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
        },
        {
          "Effect": "Allow",
          "Action": [
              "sns:CreateTopic",
              "sns:DeleteTopic",
              "sns:SetTopicAttributes",
              "sns:GetTopicAttributes",
              "sns:ListTagsForResource",

              "sns:Subscribe",
              "sns:Unsubscribe",
              "sns:GetSubscriptionAttributes"
          ],
          "Resource": "*"
        }
    ]
  }
  EOF
}
