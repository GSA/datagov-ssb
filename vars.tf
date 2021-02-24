# Vars for accessing Cloud Foundry to manage the deployment of the broker
# and manage the broker's registration in various spaces
variable "cf_api_url" {
  default     = "https://api.fr.cloud.gov"
  description = "URL for the API of your Cloud Foundry deployment"
}
variable "cf_username" {
  description = "Cloud Foundry user to use for deploying and registering the broker"
}
variable "cf_password" {
  description = "Password for the Cloud Foundry user"
}

# Vars for provisioning and managing resources in AWS
variable "aws_access_key_id" {
  description = "AWS access key to use for managing resources. Policy requirements: https://github.com/pivotal/cloud-service-broker/blob/master/docs/aws-installation.md#required-iam-policies"
}
variable "aws_secret_access_key" {
  description = "AWS secret for the access key"
}

variable "broker_space" {
  description = "The space where the broker itself should be deployed"
  type        = object({ org = string, space = string })
  default = {
    org   = "gsa-datagov"
    space = "management"
  }
}

variable "client_spaces" {
  description = "The spaces where the broker should be available. A map where keys are org names, and the values are sets of spaces in that org. If none, the broker will not be restricted to a space"
  type        = map(set(string))

  default = {
    # orgname    = [ "space1", "space2" ]
    gsa-datagov = ["development", "staging", "prod", "management"]
  }
}

