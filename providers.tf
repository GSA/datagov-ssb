provider "aws" {
  region                  = "us-west-2"
  shared_credentials_file = "/root/.aws/credentials"
  profile                 = var.aws_profile
}

# A separate provider for creating KMS keys in the us-east-1 region, which is required for DNSSEC.
# See https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-cmk-requirements.html
provider "aws" {
  alias                   = "dnssec-key-provider"
  region                  = "us-east-1"
  shared_credentials_file = "/root/.aws/credentials"
  profile                 = var.aws_profile
}

provider "cloudfoundry" {
  # Configure the CloudFoundry Provider
  api_url  = var.cf_api_url
  user     = var.cf_username
  password = var.cf_password
}

