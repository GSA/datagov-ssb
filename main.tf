terraform {
  backend "s3" {}
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
resource "aws_route53_zone" "zone" {
  count = var.manage_zone ? 1 : 0
  name  = var.broker_zone
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

data "cloudfoundry_service" "k8s" {
  name = "aws-eks-service"
}

resource "cloudfoundry_service_instance" "db" {
  for_each     = toset(local.broker_names)
  name         = "ssb-db-${each.key}"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = data.cloudfoundry_service.rds.service_plans["shared-mysql"]
  tags         = ["mysql"]
}
resource "random_uuid" "client_username" {}
resource "random_password" "client_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

data "archive_file" "app_zip" {
  for_each    = toset(local.broker_names)
  type        = "zip"
  source_dir  = "./app-${each.key}"
  output_path = "./app-${each.key}.zip"
}

resource "cloudfoundry_app" "ssb" {
  for_each         = toset(local.broker_names)
  space            = data.cloudfoundry_space.broker_space.id
  name             = "ssb-${each.key}"
  path             = data.archive_file.app_zip[each.key].output_path
  buildpack        = "binary_buildpack"
  command          = "source .profile && ./cloud-service-broker serve"
  instances        = var.ssb_app_instances
  memory           = var.ssb_app_memory
  disk_quota       = var.ssb_app_disk_quota
  enable_ssh       = false
  source_code_hash = data.archive_file.app_zip[each.key].output_base64sha256
  strategy         = "blue-green"
  service_binding {
    service_instance = cloudfoundry_service_instance.db[each.key].id
  }
  # service_binding {
  #   service_instance = cloudfoundry_service_instance.k8s.id
  # }

  environment = {
    SECURITY_USER_NAME                       = random_uuid.client_username.result,
    SECURITY_USER_PASSWORD                   = random_password.client_password.result,
    AWS_ACCESS_KEY_ID                        = var.aws_access_key_id,
    AWS_SECRET_ACCESS_KEY                    = var.aws_secret_access_key,
    AWS_DEFAULT_REGION                       = "us-east-1",
    DB_TLS                                   = "skip-verify",
    GSB_COMPATIBILITY_ENABLE_CATALOG_SCHEMAS = true,
    GSB_COMPATIBILITY_ENABLE_CF_SHARING      = true,

  }
  routes {
    route = cloudfoundry_route.ssb_uri[each.key].id
  }
}

# Give the broker a random route
data "cloudfoundry_domain" "apps" {
  sub_domain = "app"
}
resource "random_pet" "client_hostname" {}
resource "cloudfoundry_route" "ssb_uri" {
  for_each = toset(local.broker_names)
  domain   = data.cloudfoundry_domain.apps.id
  space    = data.cloudfoundry_space.broker_space.id
  hostname = "ssb-${random_pet.client_hostname.id}-${each.key}"
}

# Register the broker in each of these spaces
data "cloudfoundry_space" "spaces" {
  for_each = local.spaces_in_orgs
  name     = each.value.space
  org_name = each.value.org
}

resource "cloudfoundry_service_broker" "space-scoped-broker" {

  # local.broker_registrations is a list, so we must project it into a map
  # where each key is unique.
  # See https://www.terraform.io/docs/language/functions/setproduct.html#finding-combinations-for-for_each
  for_each = {
    for registration in local.broker_registrations : registration.name => registration
  }
  fail_when_catalog_not_accessible = true
  name                             = each.value.name
  url                              = "https://${cloudfoundry_route.ssb_uri[each.value.broker].endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  space                            = data.cloudfoundry_space.spaces[each.value.space].id

  depends_on = [
    cloudfoundry_app.ssb
  ]
}

# If no client_spaces were specified, try to register this as broker globally.
# This only works if the CF credentials provided belong to an administrator.
resource "cloudfoundry_service_broker" "standard-broker" {
  count                            = local.spaces_in_orgs == {} ? 1 : 0
  for_each                         = toset(local.broker_names)
  fail_when_catalog_not_accessible = true
  name                             = "ssb-standard-${each.key}"
  url                              = "https://${cloudfoundry_route.ssb_uri[each.key].endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  depends_on = [
    cloudfoundry_app.ssb
  ]
}

resource "cloudfoundry_service_instance" "k8s-for-space-scoped-broker" {
  count        = local.spaces_in_orgs == {} ? 0 : 1
  name         = "ssb-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = data.cloudfoundry_service.k8s.service_plans["raw"]
  tags         = ["k8s"]
  depends_on = [
    cloudfoundry_service_broker.space-scoped-broker
  ]
}

resource "cloudfoundry_service_instance" "k8s-for-global-scoped-broker" {
  count        = local.spaces_in_orgs == {} ? 1 : 0
  name         = "ssb-k8s"
  space        = data.cloudfoundry_space.broker_space.id
  service_plan = data.cloudfoundry_service.k8s.service_plans["raw"]
  tags         = ["k8s"]
  depends_on = [
    cloudfoundry_service_broker.standard-broker
  ]
}

