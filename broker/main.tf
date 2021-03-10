data "cloudfoundry_space" "broker_space" {
  name     = var.broker_space.space
  org_name = var.broker_space.org
}

data "cloudfoundry_service" "rds" {
  name = "aws-rds"
}

resource "cloudfoundry_service_instance" "db" {
  name         = "${var.name}-db"
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
  type        = "zip"
  source_dir  = var.path
  output_path = "./app-${var.name}.zip"
}

resource "cloudfoundry_app" "ssb" {
  space            = data.cloudfoundry_space.broker_space.id
  name             = var.name
  path             = data.archive_file.app_zip.output_path
  buildpack        = "binary_buildpack"
  command          = var.command
  instances        = var.instances
  memory           = var.memory
  disk_quota       = var.disk
  enable_ssh       = false
  source_code_hash = data.archive_file.app_zip.output_base64sha256
  strategy         = "blue-green"
  service_binding {
    service_instance = cloudfoundry_service_instance.db.id
  }

  dynamic "service_binding" {
    for_each = var.services
    content {
      service_instance = service_binding.value
    }
  }

  environment = {
    SECURITY_USER_NAME                       = random_uuid.client_username.result,
    SECURITY_USER_PASSWORD                   = random_password.client_password.result,
    AWS_ACCESS_KEY_ID                        = var.aws_access_key_id,
    AWS_SECRET_ACCESS_KEY                    = var.aws_secret_access_key,
    AWS_DEFAULT_REGION                       = var.aws_region,
    DB_TLS                                   = "skip-verify",
    GSB_COMPATIBILITY_ENABLE_CATALOG_SCHEMAS = true,
    GSB_COMPATIBILITY_ENABLE_CF_SHARING      = true,
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
  hostname = "ssb-${random_pet.client_hostname.id}"
}

# Register the broker in each of these spaces
data "cloudfoundry_space" "spaces" {
  for_each = local.spaces_in_orgs
  name     = each.value.space
  org_name = each.value.org
}

resource "cloudfoundry_service_broker" "space_scoped_broker" {
  for_each                         = local.spaces_in_orgs
  fail_when_catalog_not_accessible = true
  name                             = "ssb-${var.name}-${each.value.org}-${each.value.space}"
  url                              = "https://${cloudfoundry_route.ssb_uri.endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  space                            = data.cloudfoundry_space.spaces[each.key].id
  depends_on = [
    cloudfoundry_app.ssb
  ]
}

# If no client_spaces were specified, try to register this as broker globally.
# This only works if the CF credentials provided belong to an administrator.
resource "cloudfoundry_service_broker" "standard_broker" {
  count                            = local.spaces_in_orgs == {} ? 1 : 0
  fail_when_catalog_not_accessible = true
  name                             = "ssb-standard"
  url                              = "https://${cloudfoundry_route.ssb_uri.endpoint}"
  username                         = random_uuid.client_username.result
  password                         = random_password.client_password.result
  depends_on = [
    cloudfoundry_app.ssb
  ]
}

