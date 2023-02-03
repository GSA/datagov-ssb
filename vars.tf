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
  sensitive   = true
}

# Vars for provisioning and managing resources in AWS
variable "aws_target_region" {
  description = "AWS region to deploy resources to"
}
variable "aws_access_key_id" {
  description = "AWS access key to use for managing resources. Policy requirements: https://github.com/pivotal/cloud-service-broker/blob/master/docs/aws-installation.md#required-iam-policies"
}
variable "aws_secret_access_key" {
  description = "AWS secret for the access key"
  sensitive   = true
}

variable "broker_zone" {
  description = "DNS zone to use for managed resources"
}

variable "manage_zone" {
  description = "Whether to create the broker_zone"
  type        = bool
}

variable "broker_space" {
  description = "The space where the broker itself should be deployed"
  type = object({
    org   = string
    space = string
  })
}

variable "client_spaces" {
  description = "The spaces where the broker should be available. A map where keys are org names, and the values are sets of spaces in that org. If none, the broker will not be restricted to a space"
  type        = map(set(string))
  default = {
    # orgname    = [ "space1", "space2" ]
  }
}

variable "ssb_app_disk_quota" {
  default     = 2048
  description = "Disk quota (MiB) to allocate for ssb application."
}

variable "ssb_app_instances" {
  default     = 1
  description = "Number of application instances to run."
}

variable "ssb_app_memory" {
  default     = 256
  description = "Memory (MiB) to allocate for ssb application."
}

variable "enable_ssh" {
  default     = true
  description = "Whether `cf ssh` should be enabled for the broker app"
}

variable "broker_db_plan_name" {
  default     = "small-mysql"
  description = "DB plan name for the broker app"
}

variable "name_prefix" {
  default     = "ssb"
  description = "Prefix for infrastructure names, to aid in deduplication"
}
