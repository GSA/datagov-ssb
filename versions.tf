terraform {
  required_version = ">= 1.1.5"
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0.0"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry-community/cloudfoundry"
      version = "~> 0.50.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }
}
