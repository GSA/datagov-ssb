terraform {
  required_version = ">= 1.9.0"
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry-community/cloudfoundry"
      version = "~> 0.54.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.1"
    }
  }
}
