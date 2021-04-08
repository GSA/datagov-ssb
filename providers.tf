provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

provider "cloudfoundry" {
  # Configure the CloudFoundry Provider
  api_url  = var.cf_api_url
  user     = var.cf_username
  password = var.cf_password
}

