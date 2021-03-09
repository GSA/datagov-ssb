terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry-community/cloudfoundry"
      version = "~> 0.13.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
