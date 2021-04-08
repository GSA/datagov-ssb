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

variable "disk" {
  default     = 2048
  description = "Disk quota (MiB) to allocate for ssb application."
}

variable "instances" {
  default     = 1
  description = "Number of application instances to run."
}

variable "memory" {
  default     = 256
  description = "Memory (MiB) to allocate for ssb application."
}

variable "services" {
  default     = []
  description = "ID for existing service instances to be bound to the app"
}

variable "path" {
  default     = "./app"
  description = "Path to the source for the app to be pushed"
}

variable "command" {
  default     = "source .profile && ./cloud-service-broker serve"
  description = "Command to be run at app startup"
}

variable "name" {
  default     = "ssb"
  description = "Name of the application to deploy"
}

variable "aws_access_key_id" {
  description = "AWS access key to use for managing resources. Policy requirements: https://github.com/pivotal/cloud-service-broker/blob/master/docs/aws-installation.md#required-iam-policies"
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS secret for the access key"
  default     = ""
}

variable "aws_region" {
  description = "AWS region in which to manage resources."
  default     = "us-west-2"
}

variable "aws_zone" {
  description = "Route53 zone to use for SSB-provisioned resources"
  default     = ""
}
