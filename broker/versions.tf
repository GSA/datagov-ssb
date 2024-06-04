terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry-community/cloudfoundry"
      version = "~> 0.50.7"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
