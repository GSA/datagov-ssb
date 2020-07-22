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

# Vars for provisioning and managing resources in GCP
variable "gcp_credentials" {
  description = "GCP service account JSON. Policy requirements: https://github.com/pivotal/cloud-service-broker/blob/master/docs/gcp-installation.md#gcp-service-credentials"
}
variable "gcp_project" {
  description = "GCP project name"
}

