provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# A separate provider for creating KMS keys in the us-east-1 region, which is required for DNSSEC.
# See https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-cmk-requirements.html
provider "aws" {
  alias      = "dnssec-key-provider"
  region     = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

provider "cloudfoundry" {
  # Configure the CloudFoundry Provider
  api_url  = var.cf_api_url
  user     = var.cf_username
  password = var.cf_password
}

