terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "~> 0.54.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
  }
  required_version = ">= 0.13"
}
