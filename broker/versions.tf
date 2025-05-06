terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry-community/cloudfoundry"
      version = "~> 0.14.0, <= 0.14.2"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
