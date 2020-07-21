provider "random" {}
provider "local" {}

provider "cloudfoundry" {
    # Configure the CloudFoundry Provider
    api_url  = var.cf_api_url
    user     = var.cf_username
    password = var.cf_password
}

data "cloudfoundry_space" "management" {
    name = "management"
    org_name = "gsa-datagov"
}

data "cloudfoundry_service" "rds" {
    name = "aws-rds"
}

resource "cloudfoundry_service_instance" "db" {
    name = "ssb-db"
    space = data.cloudfoundry_space.management.id
    service_plan = data.cloudfoundry_service.rds.service_plans["shared-mysql"]
}

resource "cloudfoundry_service_key" "key" {
    name = "ssb-key"
    service_instance = cloudfoundry_service_instance.db.id
}

resource "random_uuid" "client_username" {}
resource "random_password" "client_password" {
    length = 16
    special = true
    override_special = "_%@"
}

# Write out the config file for the broker
resource "local_file" "broker_config" {
  sensitive_content = templatefile("./config.yml-template", 
    {   
        client_username         = random_uuid.client_username.result, 
        client_password         = random_password.client_password.result, 
        aws_access_key_id       = var.aws_access_key_id,
        aws_secret_access_key   = var.aws_secret_access_key,

        # TODO: Remove these lines once this issue is addressed: 
        # https://github.com/pivotal/cloud-service-broker/issues/49
        db_host                 = cloudfoundry_service_key.key.credentials["host"],
        db_user                 = cloudfoundry_service_key.key.credentials["username"],
        db_password             = cloudfoundry_service_key.key.credentials["password"],
        db_port                 = cloudfoundry_service_key.key.credentials["port"],
        db_name                 = cloudfoundry_service_key.key.credentials["db_name"],
    } )
  filename = "./app/config.yml"
}

data archive_file "app_zip" {
  type          = "zip"
  source_dir    = "./app"
  output_path   = "./app.zip"
  depends_on    = [
    local_file.broker_config
  ]
}

resource "cloudfoundry_app" "ssb" {
    space               = data.cloudfoundry_space.management.id
    name                = "ssb"
    path                = "./app.zip"
    buildpack           = "binary_buildpack"
    command             = "./cloud-service-broker serve --config config.yml"
    instances           = 2
    memory              = 128
    enable_ssh          = false
    source_code_hash    = data.archive_file.app_zip.output_base64sha256
    strategy            = "blue-green"
    # TODO: Use a service_binding to provide the MySQL config once this issue is
    # addressed: https://github.com/pivotal/cloud-service-broker/issues/49
    # service_binding  {
    #   TODO
    # }
}

# Give the broker a random route
data "cloudfoundry_domain" "apps" {
    sub_domain  = "app"
}
resource "random_pet" "client_hostname" {}
resource "cloudfoundry_route" "ssb_uri" {
    domain      = data.cloudfoundry_domain.apps.id
    space       = data.cloudfoundry_space.management.id
    hostname    = random_pet.client_hostname.id
    target { 
        app = cloudfoundry_app.ssb.id 
    }
}

# Register the broker in each of these spaces
# TODO: Make this set DRY
data "cloudfoundry_space" "spaces" {
    for_each = {
        development = "development"
        staging     = "staging"
        production  = "prod"
    }        
    name = each.value
    org_name = "gsa-datagov"
}

resource cloudfoundry_service_broker "ssb-broker" {
    for_each = {
        development = "development"
        staging     = "staging"
        production  = "prod"
    }        
    fail_when_catalog_not_accessible = true
    name        = "ssb-${each.value}-${var.cf_username}"
    url         = "https://${cloudfoundry_route.ssb_uri.endpoint}"
    username    = random_uuid.client_username.result
    password    = random_password.client_password.result
    space       = data.cloudfoundry_space.spaces["${each.key}"].id
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
