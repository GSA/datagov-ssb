terraform {
  required_providers {
    archive = {
      version = "~> 2.0.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "~> 0.13.0"
    }
    random = {
      version = "~> 3.0.0"
    }
    aws = {
      version = "~> 2.67"
    }
  }
  required_version = ">= 0.13"
}
