terraform {
  backend "s3" {}
}

provider "cloudfoundry" {
  # Configure the CloudFoundry Provider
  api_url  = var.cf_api_url
  user     = var.cf_username
  password = var.cf_password
}

data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

data "cloudfoundry_service" "rds" {
  name = "aws-rds"
}

resource "cloudfoundry_service_instance" "db" {
  name         = "ssb-db"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = data.cloudfoundry_service.rds.service_plans["shared-mysql"]
}

resource "cloudfoundry_service_key" "key" {
  name             = "ssb-key"
  service_instance = cloudfoundry_service_instance.db.id
}

resource "random_uuid" "client_username" {}
resource "random_password" "client_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

data archive_file "app_zip" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "./app.zip"
}

resource "cloudfoundry_app" "ssb" {
  space            = data.cloudfoundry_space.broker_space.id
  name             = "ssb"
  path             = "./app.zip"
  buildpack        = "binary_buildpack"
  command          = "./cloud-service-broker serve"
  instances        = 2
  memory           = 128
  enable_ssh       = false
  source_code_hash = data.archive_file.app_zip.output_base64sha256
  strategy         = "blue-green"
  environment = {
    SECURITY_USER_NAME     = random_uuid.client_username.result,
    SECURITY_USER_PASSWORD = random_password.client_password.result,
    AWS_ACCESS_KEY_ID      = var.aws_access_key_id,
    AWS_SECRET_ACCESS_KEY  = var.aws_secret_access_key,
    GCP_CREDENTIALS        = var.gcp_credentials,
    GCP_PROJECT            = var.gcp_project,

    # TODO: Use a service_binding to provide the MySQL config once this issue is addressed: 
    # https://github.com/pivotal/cloud-service-broker/issues/49
    DB_HOST     = cloudfoundry_service_key.key.credentials["host"]
    DB_PASSWORD = cloudfoundry_service_key.key.credentials["password"],
    DB_PORT     = cloudfoundry_service_key.key.credentials["port"],
    DB_USERNAME = cloudfoundry_service_key.key.credentials["username"],
    DB_NAME     = cloudfoundry_service_key.key.credentials["db_name"],
  }
  routes {
    route = cloudfoundry_route.ssb_uri.id
  }
  depends_on = [
    data.archive_file.app_zip
  ]
}

# Give the broker a random route
data "cloudfoundry_domain" "apps" {
  sub_domain = "app"
}
resource "random_pet" "client_hostname" {}
resource "cloudfoundry_route" "ssb_uri" {
  domain   = data.cloudfoundry_domain.apps.id
  space    = data.cloudfoundry_space.broker_space.id
  hostname = random_pet.client_hostname.id
}

# Register the broker in each of these spaces
data "cloudfoundry_space" "spaces" {
  for_each = local.spaces_in_orgs
  name     = each.value.space
  org_name = each.value.org
}

resource cloudfoundry_service_broker "space-scoped-broker" {
  for_each = local.spaces_in_orgs
  fail_when_catalog_not_accessible = true
  name                             = "ssb-${each.value.org}-${each.value.space}"
  url                              = "https://${cloudfoundry_route.ssb_uri.endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  space                            = data.cloudfoundry_space.spaces["${each.key}"].id
  depends_on = [
    cloudfoundry_app.ssb
  ]
}

# If no client_spaces were specified, try to register this as broker globally.
# This only works if the CF credentials provided belong to an administrator.
resource cloudfoundry_service_broker "standard-broker" {
  count = local.spaces_in_orgs == {} ? 1 : 0
  fail_when_catalog_not_accessible = true
  name                             = "ssb-standard"
  url                              = "https://${cloudfoundry_route.ssb_uri.endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  depends_on = [
    cloudfoundry_app.ssb
  ]
}

# ---
# TODO: Try to download the files we need as part of making Terraform go

# provider "github" {
#   anonymous     =   true
#   individual    =   true
#   version = "~> 2.9.2"
# }

# https://www.terraform.io/docs/providers/github/d/release.html
# data "github_release" "broker" {
#     repository  = "cloud-service-broker"
#     owner       = "pivotal"
#     retrieve_by = "tag"
#     # TODO: Parameterize this tag later
#     release_tag = "sb-0.1.0-rc.34-aws-0.0.1-rc.108"
# }

# provider "zipper" {
#   skip_ssl_validation = false
# }

# resource "zipper_file" "csb-release" {
#   source = "https://github.com/pivotal/cloud-service-broker.git#sb-0.1.0-rc.34-aws-0.0.1-rc.108"
#   output_path = "./csb.zip"
# }
